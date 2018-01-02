{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.client

freeipa_replica_prepare:
  cmd.run:
    - name: >
        ipa-replica-install --principal admin --admin-password {{ server.admin.password }}
