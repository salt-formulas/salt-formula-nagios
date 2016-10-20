
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

Read more
=========

* https://www.nagios.org
