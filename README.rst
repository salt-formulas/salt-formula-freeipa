
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
        domain: {{ salt['grains.get']('domain', '') }}
        realm: {{ salt['grains.get']('domain', '').upper() }}
        hostname: {{ salt['grains.get']('fqdn', '') }}

To automatically register the client with FreeIPA, you will need to first create a Kerberos principal. Start by creating a service account in FreeIPA. You may wish to restrict that users permissions to only host creation (see https://www.freeipa.org/page/HowTos#Working_with_FreeIPA). Next, you will need to obtain a kerberos ticket as admin on the IPA server, then generate a service account principl.

```bash
kinit admin
ipa-getkeytab -p service-account@EXAMPLE.com -k ./principal.keytab -s freeipahost.example.com
scp ./principal.keytab user@saltmaster.example.com:/srv/salt/freeipa/files/principal.keytab
```

Then add to your pillar:

.. code-block:: yaml
    freeipa:
      client:
        enabled: true
        server: ipa.example.com
        domain: {{ salt['grains.get']('domain', '') }}
        realm: {{ salt['grains.get']('domain', '').upper() }}
        hostname: {{ salt['grains.get']('fqdn', '') }}
        install_principal:
          source: salt://freeipa/files/principal.keytab
          mode: 0600
          principal_user: "service-account"
          file_user: "root"
          file_group: "root"

This will allow your client to use FreeIPA's JSON interface to create a host entry with a One Time Password and then register to the FreeIPA server. For security purposes, the kerberos principl will only be pushed down to the client if the installer reports it is not registered to the FreeIPA server and will be removed from the client as soon as the endpoint has registered with the FreeIPA server.

Additionally, the openssh formula (see https://github.com/salt-formulas/salt-formula-openssh) is needed and is a dependancy for this formula. Configure it thusly:

.. code-block:: yaml

    openssh:
      server:
        public_key_auth: true
        gssapi_auth: true
        kerberos_auth: false
        authorized_keys_command:
          command: /usr/bin/sss_ssh_authorizedkeys
          user: nobody

If you wish to update DNS records using nsupdate, add:

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

For requesting certificates using certmonger:

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
