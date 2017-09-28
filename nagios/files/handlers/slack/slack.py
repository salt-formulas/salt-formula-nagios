#!/usr/bin/env python

from argparse import ArgumentParser
import json
import logging
import requests
import sys


def main():
    parser = ArgumentParser()
    parser.add_argument('--webhook-url', required=True, help="Slack webhook url")
    parser.add_argument('--desc', required=True, help='use "-" to use stdin')
    parser.add_argument('--notification-type', required=True,
                        help='PROBLEM|RECOVERY|etc ($NOTIFICATIONTYPE$)')
    parser.add_argument('--state', required=True,
                        help='OK|WARNING|CRITICAL|UNKNOWN|UP|DOWN|UNREACHABLE'
                             ' $SERVICESTATE$ or $HOSTSTATE$')
    parser.add_argument('--hostname', required=True, help='$HOSTNAME$')
    parser.add_argument('--service-desc', required=False, help='$SERVICEDESC$')

    parser.add_argument('--syslog', action='store_true', default=False,
                        help='Log to syslog')
    parser.add_argument('--debug', action='store_true', default=False)
    parser.add_argument('--log-file', default=sys.stdout, help='default stdout')

    args = parser.parse_args()

    LOG = logging.getLogger()
    if args.syslog:
        handler = logging.SysLogHandler()
    elif (args.log_file != sys.stdout):
        handler = logging.FileHandler(args.log_file)
    else:
        handler = logging.StreamHandler(sys.stdout)

    if args.debug:
        log_level = logging.DEBUG
    else:
        log_level = logging.INFO

    formatter = logging.Formatter(
        'nagios_to_slack %(asctime)s %(process)d %(levelname)s %(name)s '
        '[-] %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    handler.setFormatter(formatter)
    LOG.setLevel(log_level)
    LOG.addHandler(handler)

    if args.desc == '-':
        args.desc = ''.join(sys.stdin.readlines())

    state_color = {
        'OK': 'good',
        'UNKNOWN': 'gray',
        'WARNING': 'warning',
        'CRITICAL': 'danger',
        'UP': 'good',
        'DOWN': 'danger',
        'UNREACHABLE': 'danger',
    }

    if args.service_desc:
        title = '{:s} {:s}/{:s}'.format(args.state, args.hostname,
                                        args.service_desc)
    else:
        title = '{:s} {:s}'.format(args.state, args.hostname)

    slack_data = {
        'color': state_color[args.state],
        'icon_emoji': ':ghost:',
        'fields': [
            {
                'title': args.notification_type,
                'value': title
            },
            {
                'title': 'Description',
                'value': args.desc
            }
        ]
    }

    LOG.debug('Nagios data: {} '.format(slack_data))

    r = requests.post(args.webhook_url, data=json.dumps(slack_data))
    LOG.debug("Response: {:d} {:s}".format(r.status_code, r.text))


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
