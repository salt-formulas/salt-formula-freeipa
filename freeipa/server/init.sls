{%- from "freeipa/map.jinja" import server, ipa_servers with context %}

include:
{%- if ipa_servers.0 != server.get('hostname', grains['fqdn']) %}
- freeipa.server.replica
{%- else %}
- freeipa.server.master
{%- endif %}
