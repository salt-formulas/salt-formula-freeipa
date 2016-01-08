{%- from "freeipa/map.jinja" import server, ipa_servers with context %}

include:
{%- if ipa_servers.0 == server.get('hostname', grains['fqdn']) %}
{# We are first server in a list, so master #}
- freeipa.server.master
{%- else %}
- freeipa.server.replica
{%- endif %}
