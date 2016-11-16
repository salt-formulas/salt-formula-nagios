# -*- coding: utf-8 -*-

def alarm_to_service(host, alarm_id, alarm, check_command, threshold, default=None):
    """
    Return a dictinnary representing a Nagios service from an alarm definition.
    The service properties are enforced to activate passive check and turn on the
    freshness pattern.
    """
    if default is None:
        default = {}

    notifications_enabled = 0
    alerting = alarm.get('alerting', 'enabled')
    if alerting == 'enabled_with_notification':
        notifications_enabled = 1

    service = {
        'service_description': alarm_id,
        'host_name': host,
        'notifications_enabled': notifications_enabled,
        'freshness_threshold': threshold,
        'check_command': check_command,
        'passive_checks_enabled': 1,
        'active_checks_enabled': 0,
        'check_freshness': 1,
    }
    service.update(default)
    return {host + alarm_id: service }


def threshold(alarm, triggers, delay=10):
    """
    Return the freshness_threshold for a Nagios service based on the maximum
    window used by triggers.
    An additional delay is applied to prevent flapping when collectors
    are (re)started.
    """

    window = 10
    for trigger in alarm.get('triggers', []):
        if trigger in triggers:
            for rule in triggers[trigger].get('rules', []):
                if rule.get('window', 0) > window:
                    window = int(rule.get('window'))

    return window + delay
