#!/bin/sh
set -e

case "$1" in
'celery')
    exec celery \
        --app=cl worker \
        --loglevel=info \
        --events \
        --pool=prefork \
        --hostname=prefork@%h \
        --queues=${CELERY_QUEUES} \
        --concurrency=${CELERY_PREFORK_CONCURRENCY:-0} \
        --prefetch-multiplier=${CELERY_PREFETCH_MULTIPLIER:-1}
    ;;
'web-dev')
    python /opt/courtlistener/manage.py migrate
    python /opt/courtlistener/manage.py createcachetable
    exec python /opt/courtlistener/manage.py runserver 0.0.0.0:8000
    ;;
'web-prod')
    # Tips:
    # 1. Set high number of --workers. Docs recommend 2-4× core count
    # 2. Set --limit-request-line to high value to allow long search queries
    exec gunicorn cl.asgi:application \
        --chdir /opt/courtlistener/ \
        --user www-data \
        --group www-data \
        --workers ${NUM_WORKERS:-48} \
        --worker-class cl.workers.UvicornWorker \
        --limit-request-line 6000 \
        --timeout 0 \
        --max-requests 500 \
        --max-requests-jitter 50 \
        --bind 0.0.0.0:8000
    ;;
'rss-scraper')
    exec /opt/courtlistener/manage.py scrape_rss
    ;;
'retry-webhooks')
    exec /opt/courtlistener/manage.py cl_retry_webhooks
    ;;
'sweep-indexer')
    exec /opt/courtlistener/manage.py sweep_indexer
    ;;
'probe-iquery-pages-daemon')
    exec /opt/courtlistener/manage.py probe_iquery_pages_daemon
    ;;
'cl-send-rt-percolator-alerts')
    exec /opt/courtlistener/manage.py cl_send_rt_percolator_alerts
    ;;
*)
    echo "Unknown command"
    ;;
esac
