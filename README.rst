
==================================
freeipa
==================================

FreeIPA Identity Management service and client

Sample pillars
==============

Client
------

.. code-block:: yaml

    freeipa:
      client:
        enabled: true
        server: ipa.example.com
        domain: ${linux:network:domain}
        hostname: ${linux:network:fqdn}

Read more
=========

* http://www.freeipa.org/page/Quick_Start_Guide
