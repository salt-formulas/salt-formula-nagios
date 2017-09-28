nagios:
  server:
    enabled: true
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
