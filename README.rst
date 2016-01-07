
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
        realm: ${linux:network:domain}
        hostname: ${linux:network:fqdn}

If you are using openssh formula, this is needed for FreeIPA authentication:

.. code-block:: yaml

    openssh:
      server:
        public_key_auth: true
        gssapi_auth: true
        kerberos_auth: false
        authorized_keys_command:
          command: /usr/bin/sss_ssh_authorizedkeys
          user: nobody

Server
------

.. code-block:: yaml

    parameters:
      freeipa:
        server:
          realm: IPA.EXAMPLE.COM
          domain: ipa.example.com
          admin:
            password: secretpassword
          ldap:
            password: secretpassword

Read more
=========

* http://www.freeipa.org/page/Quick_Start_Guide
