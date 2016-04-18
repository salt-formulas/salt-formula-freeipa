
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

Update DNS records using nsupdate:

.. code-block:: yaml

    freeipa:
      client:
        nsupdate:
          - name: test.example.com
            ipv4:
              - 8.8.8.8
            ipv6:
              - 2a00:1450:4001:80a::1009
            ttl: 1800
            keytab: /etc/krb5.keytab

Request certificate using certmonger:

.. code-block:: yaml

    freeipa:
      client:
        cert:
          "HTTP/www.example.com":
            user: root
            group: www-data
            mode: 640
            cert: /etc/ssl/certs/http-www.example.com.crt
            key: /etc/ssl/private/http-www.example.com.key

Server
------

.. code-block:: yaml

    freeipa:
      server:
        realm: IPA.EXAMPLE.COM
        domain: ipa.example.com
        admin:
          password: secretpassword
        ldap:
          password: secretpassword

Disable LDAP access logs but enable audit

.. code-block:: yaml

    freeipa:
      server:
        ldap:
          logging:
            access: false
            audit: true

Read more
=========

* http://www.freeipa.org/page/Quick_Start_Guide
