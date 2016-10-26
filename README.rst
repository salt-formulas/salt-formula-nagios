
======
nagios
======

Salt formula to set up and manage nagios

Available states
================

``nagios.server``

Set up Nagios server


Sample pillars
==============

Single nagios service

.. code-block:: yaml

    nagios:
      server:
        enabled: true

All Nagios configurations can be configured

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        accept_passive_service_checks: 1
        process_performance_data: 0
        check_service_freshness: 1
        check_host_freshness: 0

Nagios UI configrations

.. code-block:: yaml

    nagios:
      server:
        enabled: true
        ui_username: nagiosadmin
        ui_password: secret

Read more
=========

* https://www.nagios.org
