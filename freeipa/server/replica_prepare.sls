{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.server.common

{# /var/lib/ipa/replica-info-ipareplica.example.com.gpg #}

freeipa_replica_prepare:
  cmd.run:
    - name: >
        ipa-replica-prepare freeipa2.ci.kitchenci --ip-address 127.0.2.1 -p {{ server.ldap.password }}
