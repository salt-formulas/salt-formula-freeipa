
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

Server definition for new verion of freeipa (4.3+). Replicas dont require generation of gpg file on master. But principal user has to be defined with

.. code-block:: yaml

    freeipa:
      server:
        realm: IPA.EXAMPLE.COM
        domain: ipa.example.com
        principal_user: admin
        admin:
          password: secretpassword
        servers:
        - idm01.ipa.example.com
        - idm02.ipa.example.com
        - idm03.ipa.example.com


Disable CA. Default is True.

.. code-block:: yaml

    freeipa:
      server:
        ca: false


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

Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-freeipa/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-freeipa

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
