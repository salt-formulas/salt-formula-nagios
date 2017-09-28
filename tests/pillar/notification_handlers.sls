nagios:
  server:
    enabled: true
    objects:
      hosts:
        generic_host_tpl:
          notification_interval: 30
      services:
        generic_service_tpl:
          notification_interval: 30
    notification:
      alarm_enabled_override: true
      slack:
        enabled: true
        webhook_url: https://hooks.slack.com/services/abcdef/123456/abcdef12345
      sfdc:
        enabled: true
        client_id: abcdef12345
        client_secret: abcdef12345
        username: abcdef12345
        password: abcdef12345
        auth_url: https://example.my.salesforce.com
        environment: abcdef12345
        organization_id: abcdef12345
      pagerduty:
        enabled: true
        key: abcdef12345
    dynamic:
      enabled: true
      grain_hostname: host
      hostgroups:
      - expr_from: compound
        name: All
        target: G@services:openssh
      hostname_suffix: test.local
      hosts:
      - contact_groups: Operator
        interface:
        - eth0
        network: []
        target: G@services:openssh
        use: generic_host_tpl
      services:
      - check_command: check_ssh
        name: SSH
        target: G@roles:openssh.server
        use: generic_service_tpl
      stacklight_alarm_clusters:
        default_host: 00-clusters
        dimension_key: nagios_host
        enabled: true 
        host_template: generic_host_tpl
        service_template: generic_service_tpl
      stacklight_alarms:
        enabled: true 
        service_template: generic_service_tpl
