# Copyright 2014-2018 CERN for the benefit of the ATLAS collaboration.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Authors:
# - Thomas Beermann <thomas.beermann@cern.ch>, 2014-2018
# - Ralph Vigne <ralph.vigne@cern.ch>, 2014
# - Vincent Garonne <vgaronne@gmail.com>, 2015-2018
# - Mario Lassnig <mario.lassnig@cern.ch>, 2015
# - Wen Guan <wguan.icedew@gmail.com>, 2015
# - Cedric Serfon <cedric.serfon@cern,ch>, 2018
# - Robert Illingworth <illingwo@fnal.gov>, 2018
# - Andrew Lister <andrew.lister@stfc.ac.uk>, 2019
#
# PY3K COMPATIBLE

"""
This daemon consumes tracer messages from ActiveMQ and updates the atime for replicas.
"""

import inspect
import logging
import re
import socket

from datetime import datetime
from json import loads as jloads, dumps as jdumps
from os import getpid
try:
    from Queue import Queue  # py2
except ImportError:
    from queue import Queue  # py3
from sys import stdout
from threading import Event, Thread, current_thread
from time import sleep, time
from traceback import format_exc

from stomp import Connection

from rucio.common.config import config_get, config_get_bool, config_get_int
from rucio.common.exception import ConfigNotFound
from rucio.common.types import InternalAccount, InternalScope
from rucio.core.monitor import record_counter, record_timer
from rucio.core.config import get
from rucio.core.did import touch_dids, list_parent_dids
from rucio.core.heartbeat import live, die, sanity_check
from rucio.core.lock import touch_dataset_locks
from rucio.core.replica import touch_replica, touch_collection_replicas, declare_bad_file_replicas
from rucio.core.rse import get_rse_id
from rucio.db.sqla.constants import DIDType, BadFilesStatus

logging.getLogger("stomp").setLevel(logging.DEBUG)

logging.basicConfig(stream=stdout,
                    level=getattr(logging,'DEBUG'),
                    format='%(asctime)s\t%(process)d\t%(levelname)s\t%(threadName)s\t%(message)s')

graceful_stop = Event()


def f2():
    s = inspect.stack()
    logging.debug( "===Current function===:")
    logging.debug("line number: %d" %s[0][2])
    print ("function name: %s" %s[0][3])
    
    logging.debug( "===Caller function===")
    logging.debug("line number: %d" %s[1][2])
    logging.debug("function name: %s" %s[1][3])
    
    logging.debug("===Outermost call===")
    logging.debug("line number: %d" %s[2][2])
    logging.debug("function name: %s" %s[2][3])


class AMQConsumer(object):
    def __init__(self, broker, conn, queue, chunksize, subscription_id, excluded_usrdns, dataset_queue, bad_files_patterns):
        self.__broker = broker
        self.__conn = conn
        self.__queue = queue
        self.__reports = []
        self.__ids = []
        self.__chunksize = chunksize
        self.__subscription_id = subscription_id
        # excluded states empty for the moment, maybe that should be recosidered in the future
        self.__excluded_states = set([])
        # exclude specific usrdns like GangaRBT
        self.__excluded_usrdns = excluded_usrdns
        self.__dataset_queue = dataset_queue
        self.__bad_files_patterns = bad_files_patterns
        logging.debug('create a AMQConsumer... YYG')
        f2()
   
    def on_error(self, headers, message):
        f2()
        record_counter('daemons.tracer.kronos.error')
        logging.error('[%s] %s' % (self.__broker, message))

    def on_message(self, headers, message):
        f2()
        logging.debug('on_messages ... YYG')
        record_counter('daemons.tracer.kronos.reports')

        appversion = 'dq2'
        msg_id = headers['message-id']
        if 'appversion' in headers:
            appversion = headers['appversion']

        if 'resubmitted' in headers:
            record_counter('daemons.tracer.kronos.received_resubmitted')
            logging.debug('(kronos_file on message) got a resubmitted report')

        try:
            if appversion == 'dq2':
                self.__conn.ack(msg_id, self.__subscription_id)
                return
            else:
                f2()
                report = jloads(message)
                logging.debug("message of on_messages: " + message )      
        except Exception:
            # message is corrupt, not much to do here
            # send count to graphite, send ack to broker and return
            record_counter('daemons.tracer.kronos.json_error')
            logging.error('(kronos_file) json error')
            self.__conn.ack(msg_id, self.__subscription_id)
            f2()
            return

        self.__ids.append(msg_id)
        self.__reports.append(report)

        try:
            logging.debug('(kronos_file on_messages ) message received: %s %s %s' % (str(report['eventType']), report['filename'], report['remoteSite']))
        except Exception:
            pass
 
        logging.debug('(kronos_file on_messages ) chunksize: %d' %self.__chunksize)
        if len(self.__ids) >= self.__chunksize:
            logging.debug('(kronos_file on_messages ) calling __upate_atime() ... YYG')
            self.__update_atime()
            logging.debug('(kronos_file on_messages ) done calling_upate_atime() ... YYG')
            for msg_id in self.__ids:
                self.__conn.ack(msg_id, self.__subscription_id)
                f2()
            self.__reports = []
            self.__ids = []

    def __update_atime(self):
        """
        Bulk update atime.
        """
        f2()
        logging.debug('(__upate_atime()) just got in  ... YYG')
        replicas = []
        rses = []
        for report in self.__reports:
            try:
                # Identify suspicious files
                try:
                    if self.__bad_files_patterns and report['eventType'] in ['get_sm', 'get_sm_a', 'get'] and 'clientState' in report and report['clientState'] not in ['DONE', 'FOUND_ROOT', 'ALREADY_DONE']:
                        for pattern in self.__bad_files_patterns:
                            if 'stateReason' in report and report['stateReason'] and isinstance(report['stateReason'], str) and pattern.match(report['stateReason']):
                                reason = report['stateReason'][:255]
                                if 'url' not in report or not report['url']:
                                    logging.error('Missing url in the following trace : ' + str(report))
                                else:
                                    try:
                                        surl = report['url']
                                        declare_bad_file_replicas([surl, ], reason=reason, issuer=InternalAccount('root'), status=BadFilesStatus.SUSPICIOUS)
                                        logging.info('Declare suspicious file %s with reason %s' % (report['url'], reason))
                                    except Exception as error:
                                        logging.error('Failed to declare suspicious file' + str(error))
                except Exception as error:
                    logging.error('Problem with bad trace : %s . Error %s' % (str(report), str(error)))

                # check if scope in report. if not skip this one.
                if 'scope' not in report:
                    record_counter('daemons.tracer.kronos.missing_scope')
                    if report['eventType'] != 'touch':
                        continue
                else:
                    record_counter('daemons.tracer.kronos.with_scope')
                    report['scope'] = InternalScope(report['scope'])

                # handle all events starting with get* and download and touch events.
                if not report['eventType'].startswith('get') and not report['eventType'].startswith('sm_get') and not report['eventType'] == 'download' and not report['eventType'] == 'touch':
                    continue
                if report['eventType'].endswith('_es'):
                    continue
                record_counter('daemons.tracer.kronos.total_get')
                if report['eventType'] == 'get':
                    record_counter('daemons.tracer.kronos.dq2clients')
                elif report['eventType'] == 'get_sm' or report['eventType'] == 'sm_get':
                    if report['eventVersion'] == 'aCT':
                        record_counter('daemons.tracer.kronos.panda_production_act')
                    else:
                        record_counter('daemons.tracer.kronos.panda_production')
                elif report['eventType'] == 'get_sm_a' or report['eventType'] == 'sm_get_a':
                    if report['eventVersion'] == 'aCT':
                        record_counter('daemons.tracer.kronos.panda_analysis_act')
                    else:
                        record_counter('daemons.tracer.kronos.panda_analysis')
                elif report['eventType'] == 'download':
                    record_counter('daemons.tracer.kronos.rucio_download')
                elif report['eventType'] == 'touch':
                    record_counter('daemons.tracer.kronos.rucio_touch')
                else:
                    record_counter('daemons.tracer.kronos.other_get')

                if report['eventType'] == 'download' or report['eventType'] == 'touch':
                    report['usrdn'] = report['account']

                if report['usrdn'] in self.__excluded_usrdns:
                    continue

                # handle touch and non-touch traces differently
                if report['eventType'] != 'touch':
                    # check if the report has the right state.
                    if 'eventVersion' in report:
                        if report['eventVersion'] != 'aCT':
                            if report['clientState'] in self.__excluded_states:
                                continue

                    if 'remoteSite' not in report:
                        continue
                    if not report['remoteSite']:
                        continue

                    if 'filename' not in report:
                        if 'name' in report:
                            report['filename'] = report['name']

                    rses = report['remoteSite'].strip().split(',')
                    for rse in rses:
                        rse_id = get_rse_id(rse=rse)
                        logging.debug('(__upate_atime()) update replicas  .. YYG')
                        replicas.append({'name': report['filename'], 'scope': report['scope'], 'rse': rse, 'rse_id': rse_id, 'accessed_at': datetime.utcfromtimestamp(report['traceTimeentryUnix']),
                                         'traceTimeentryUnix': report['traceTimeentryUnix'], 'eventVersion': report['eventVersion']})
                        logging.debug(replicas)
                else:
                    # if touch event and if datasetScope is in the report then it means
                    # that there is no file scope/name and therefore only the dataset is
                    # put in the queue to be updated and the rest is skipped.
                    rse_id = None
                    rse = None
                    if 'remoteSite' in report:
                        rse = report['remoteSite']
                        rse_id = get_rse_id(rse=rse)
                        logging.debug('(__upate_atime(), res_id %d'%res_id) 
                    if 'datasetScope' in report:
                        logging.debug('(__upate_atime()) update __dataset_queue while datasetScope in report .. YYG')
                        self.__dataset_queue.put({'scope': report['datasetScope'], 'name': report['dataset'], 'rse_id': rse_id, 'accessed_at': datetime.utcfromtimestamp(report['traceTimeentryUnix'])})
                        f2()
                        continue
                    else:
                        if 'remoteSite' not in report:
                            continue
                        logging.debug('(__upate_atime()) update replicas 2  .. YYG')
                        replicas.append({'name': report['filename'], 'scope': report['scope'], 'rse': rse, 'rse_id': rse_id, 'accessed_at': datetime.utcfromtimestamp(report['traceTimeentryUnix'])})
                        logging.debug(replicas)

            except (KeyError, AttributeError):
                logging.error(format_exc())
                record_counter('daemons.tracer.kronos.report_error')
                f2()
                continue

            for did in list_parent_dids(report['scope'], report['filename']):
                if did['type'] != DIDType.DATASET:
                    continue
                # do not update _dis datasets
                if did['scope'].external == 'panda' and '_dis' in did['name']:
                    continue
                for rse in rses:
                    rse_id = get_rse_id(rse=rse)
                    logging.debug('(__upate_atime()) update __dataset_queue')
                    self.__dataset_queue.put({'scope': did['scope'], 'name': did['name'], 'did_type': did['type'], 'rse_id': rse_id, 'accessed_at': datetime.utcfromtimestamp(report['traceTimeentryUnix'])})
                    f2()
        logging.debug('checking replicas in __update_atime')
        logging.debug(replicas)

        try:
            f2()
            start_time = time()
            for replica in replicas:
                # if touch replica hits a locked row put the trace back into queue for later retry
                logging.debug('(__upate_atime()) update a replica for accessing time')
                if not touch_replica(replica):
                    resubmit = {'filename': replica['name'], 'scope': replica['scope'].external, 'remoteSite': replica['rse'], 'traceTimeentryUnix': replica['traceTimeentryUnix'],
                                'eventType': 'get', 'usrdn': 'someuser', 'clientState': 'DONE', 'eventVersion': replica['eventVersion']}
                    self.__conn.send(body=jdumps(resubmit), destination=self.__queue, headers={'appversion': 'rucio', 'resubmitted': '1'})
                    record_counter('daemons.tracer.kronos.sent_resubmitted')
                    logging.warning('(kronos_file) hit locked row, resubmitted to queue')
            record_timer('daemons.tracer.kronos.update_atime', (time() - start_time) * 1000)
        except Exception:
            logging.error(format_exc())
            record_counter('daemons.tracer.kronos.update_error')
            f2()

        logging.info('(kronos_file) updated %d replicas' % len(replicas))


def kronos_file(once=False, thread=0, brokers_resolved=None, dataset_queue=None, sleep_time=60):
    """
    Main loop to consume tracer reports.
    """

    logging.info('(kronos_file) tracer consumer starting')
    f2()
    hostname = socket.gethostname()
    pid = getpid()
    thread = current_thread()

    chunksize = config_get_int('tracer-kronos', 'chunksize')
    prefetch_size = config_get_int('tracer-kronos', 'prefetch_size')
    subscription_id = config_get('tracer-kronos', 'subscription_id')
    try:
        bad_files_patterns = []
        pattern = get(section='kronos', option='bad_files_patterns', session=None)
        pattern = str(pattern)
        patterns = pattern.split(",")
        for pat in patterns:
            bad_files_patterns.append(re.compile(pat.strip()))
    except ConfigNotFound:
        bad_files_patterns = []
    except Exception as error:
        logging.error('(kronos_file) Failed to get bad_file_patterns' + str(error))
        bad_files_patterns = []

    use_ssl = True
    try:
        use_ssl = config_get_bool('tracer-kronos', 'use_ssl')
    except Exception:
        pass

    if not use_ssl:
        username = config_get('tracer-kronos', 'username')
        password = config_get('tracer-kronos', 'password')

    excluded_usrdns = set(config_get('tracer-kronos', 'excluded_usrdns').split(','))
    vhost = config_get('tracer-kronos', 'broker_virtual_host', raise_exception=False)

    conns = []
    for broker in brokers_resolved:
        if not use_ssl:
            f2()
            conns.append(Connection(host_and_ports=[(broker, config_get_int('tracer-kronos', 'port'))],
                                    use_ssl=False,
                                    vhost=vhost,
                                    reconnect_attempts_max=config_get_int('tracer-kronos', 'reconnect_attempts')))
        else:
            f2()
            conns.append(Connection(host_and_ports=[(broker, config_get_int('tracer-kronos', 'port'))],
                                    use_ssl=True,
                                    ssl_key_file=config_get('tracer-kronos', 'ssl_key_file'),
                                    ssl_cert_file=config_get('tracer-kronos', 'ssl_cert_file'),
                                    vhost=vhost,
                                    reconnect_attempts_max=config_get_int('tracer-kronos', 'reconnect_attempts')))

    logging.info('(kronos_file) tracer consumer started')

    sanity_check(executable='kronos-file', hostname=hostname)
    while not graceful_stop.is_set():
        f2()
        start_time = time()
        live(executable='kronos-file', hostname=hostname, pid=pid, thread=thread)
        for conn in conns:
            if not conn.is_connected():
                logging.info('(kronos_file) connecting to %s' % conn.transport._Transport__host_and_ports[0][0])
                logging.info('starting debugging ... YYG')
                record_counter('daemons.tracer.kronos.reconnect.%s' % conn.transport._Transport__host_and_ports[0][0].split('.')[0])
                conn.set_listener('rucio-tracer-kronos', AMQConsumer(broker=conn.transport._Transport__host_and_ports[0],
                                                                     conn=conn,
                                                                     queue=config_get('tracer-kronos', 'queue'),
                                                                     chunksize=chunksize,
                                                                     subscription_id=subscription_id,
                                                                     excluded_usrdns=excluded_usrdns,
                                                                     dataset_queue=dataset_queue,
                                                                     bad_files_patterns=bad_files_patterns))
                conn.start()
                f2()
                logging.info("connection started... YYG")
                if not use_ssl:
                    f2()
                    logging.info("To be connected with pd ... YYG")
                    conn.connect(username, password)
                    logging.info("connected with pd ... YYG")
                else:
                    conn.connect()
                conn.subscribe(destination=config_get('tracer-kronos', 'queue'), ack='client-individual', id=subscription_id, headers={'activemq.prefetchSize': prefetch_size})
        tottime = time() - start_time
        if tottime < sleep_time:
            f2()
            logging.info('(kronos_file) Will sleep for %s seconds' % (sleep_time - tottime))
            sleep(sleep_time - tottime)

    logging.info('(kronos_file) graceful stop requested')

    for conn in conns:
        try:
            f2()
            logging.info('(kronos_file) disconnected  ... YYG')
            conn.disconnect()
        except Exception:
            pass

    die(executable='kronos-file', hostname=hostname, pid=pid, thread=thread)
    logging.info('(kronos_file) graceful stop done')


def kronos_dataset(once=False, thread=0, dataset_queue=None, sleep_time=60):
    logging.debug('(kronos_dataset) just starting YYG')
    f2()
    hostname = socket.gethostname()
    pid = getpid()
    thread = current_thread()

    dataset_wait = config_get_int('tracer-kronos', 'dataset_wait')
    logging.debug('(kronos_dataset) starting2')
    logging.debug('(kronos_dataset) dataset_wait: %d '%dataset_wait)
    start = datetime.now()
    logging.debug('(kronos_dataset) start: %s' %start)
    sanity_check(executable='kronos-dataset', hostname=hostname)
    while not graceful_stop.is_set():
        f2()
        start_time = time()
        live(executable='kronos-dataset', hostname=hostname, pid=pid, thread=thread)
        t = datetime.now()
        logging.debug('(kronos_dataset) datetime.now() %s: ' %t)
        if (datetime.now() - start).seconds > dataset_wait:
            logging.debug('kronos_dataset: to be __update_dataset -- YYG ')
            __update_datasets(dataset_queue)
            start = datetime.now()
        tottime = time() - start_time
        if tottime < sleep_time:
            logging.info('(kronos_dataset) Will sleep for %s seconds' % (sleep_time - tottime))
            sleep(sleep_time - tottime)
    # once again for the backlog
    f2()
    die(executable='kronos-dataset', hostname=hostname, pid=pid, thread=thread)
    logging.info('(kronos_dataset) cleaning dataset backlog before shutdown...')
    logging.debug('kronos_dataset: to be __update_dataset 2 -- YYG ')
    __update_datasets(dataset_queue)


def __update_datasets(dataset_queue):
    f2()
    logging.info('(__update_dataset) starting YYG') 
    len_ds = dataset_queue.qsize()
    logging.debug('(__update_datasets) dataset_queue.qsize() : %d'%len_ds)
    datasets = {}
    dslocks = {}
    now = time()
    for _ in range(0, len_ds):
        f2()
        dataset = dataset_queue.get()
        did = '%s:%s' % (dataset['scope'].internal, dataset['name'])
        logging.debug('(__update_datasets) did: %s ' %did)
        rse = dataset['rse_id']
        if did not in datasets:
            f2()
            datasets[did] = dataset['accessed_at']
            logging.debug('(__update_datasets) 1: datasets[did]: %s' %datasets[did])
        else:
            f2()
            datasets[did] = max(datasets[did], dataset['accessed_at'])
            logging.debug('(__update_datasets) 2: datasets[did]: %s' %datasets[did])

        if rse is None:
            continue
        if did not in dslocks:
            dslocks[did] = {}
        if rse not in dslocks[did]:
            dslocks[did][rse] = dataset['accessed_at']
        else:
            dslocks[did][rse] = max(dataset['accessed_at'], dslocks[did][rse])
    logging.debug('(__update_datasets) fetched %d datasets from queue (%ds)' % (len_ds, time() - now))

    total, failed, start = 0, 0, time()
    for did, accessed_at in datasets.items():
        f2()
        scope, name = did.split(':')
        scope = InternalScope(scope, fromExternal=False)
        update_did = {'scope': scope, 'name': name, 'type': DIDType.DATASET, 'accessed_at': accessed_at}
        # if update fails, put back in queue and retry next time
        logging.debug('__update_datasets: to be touch_dids -- YYG')
        if not touch_dids((update_did,)):
            update_did['rse_id'] = None
            dataset_queue.put(update_did)
            logging.debug('__update_datasets: failed touch_dids -- YYG')
            failed += 1
        total += 1
    logging.debug('(__update_dataset) did update for %d datasets, %d failed (%ds)' % (total, failed, time() - start))

    total, failed, start = 0, 0, time()
    for did, rses in dslocks.items():
        f2()
        scope, name = did.split(':')
        scope = InternalScope(scope, fromExternal=False)
        for rse, accessed_at in rses.items():
            update_dslock = {'scope': scope, 'name': name, 'rse_id': rse, 'accessed_at': accessed_at}
            # if update fails, put back in queue and retry next time
            if not touch_dataset_locks((update_dslock,)):
                dataset_queue.put(update_dslock)
                failed += 1
            total += 1
    logging.debug('(__update_dataset) did update for %d locks, %d failed (%ds)' % (total, failed, time() - start))

    total, failed, start = 0, 0, time()
    for did, rses in dslocks.items():
        f2()
        scope, name = did.split(':')
        scope = InternalScope(scope, fromExternal=False)
        for rse, accessed_at in rses.items():
            f2()
            update_dslock = {'scope': scope, 'name': name, 'rse_id': rse, 'accessed_at': accessed_at}
            # if update fails, put back in queue and retry next time
            logging.debug('__update_datasets: to be touch_collection_replicas -- YYG')
            if not touch_collection_replicas((update_dslock,)):
                f2()
                dataset_queue.put(update_dslock)
                failed += 1
                logging.debug('__update_datasets: failed touch_collection_replicas -- YYG')
            total += 1
    logging.debug('(__update_dataset) did update for %d collection replicas, %d failed (%ds)' % (total, failed, time() - start))


def stop(signum=None, frame=None):
    """
    Graceful exit.
    """
    f2()
    graceful_stop.set()


def run(once=False, threads=1, sleep_time_datasets=60, sleep_time_files=60):
    """
    Starts up the consumer threads
    """
    logging.info('resolving brokers')
    s = inspect.stack()
    print( "===Current function===:")
    print("line number: %d" %s[0][2])
    print("function name: %s" %s[0][3])
    
    print( "===Caller function===")
    print("line number: %d" %s[1][2])
    print("function name: %s" %s[1][3])
    
    print("===Outermost call===")
    print("line number: %d" %s[2][2])
    print("function name: %s" %s[2][3])

    brokers_alias = []
    brokers_resolved = []
    try:
        brokers_alias = [b.strip() for b in config_get('tracer-kronos', 'brokers').split(',')]
    except Exception:
        raise Exception('Could not load brokers from configuration')

    logging.debug('resolving broker dns alias: %s' % brokers_alias)

    brokers_resolved = []
    for broker in brokers_alias:
        f2()
        addrinfos = socket.getaddrinfo(broker, 0, socket.AF_INET, 0, socket.IPPROTO_TCP)
        brokers_resolved.extend(ai[4][0] for ai in addrinfos)

    logging.debug('brokers resolved to %s', brokers_resolved)

    dataset_queue = Queue()
    logging.info('starting tracer consumer threads')

    thread_list = []
    f2()
    for thread in range(0, threads):
        thread_list.append(Thread(name='kronos_file_thread', target=kronos_file, kwargs={'thread': thread,
                                                              'sleep_time': sleep_time_files,
                                                              'brokers_resolved': brokers_resolved,
                                                              'dataset_queue': dataset_queue}))
        thread_list.append(Thread(name='kronos_dataset_thread', target=kronos_dataset, kwargs={'thread': thread,
                                                                 'sleep_time': sleep_time_datasets,
                                                                 'dataset_queue': dataset_queue}))

    f2()
    [thread.start() for thread in thread_list]
    f2()
    logging.info('waiting for interrupts')

    while thread_list > 0:
        f2()
        thread_list = [thread.join(timeout=3) for thread in thread_list if thread and thread.isAlive()]
