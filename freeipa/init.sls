{%- if pillar.freeipa is defined %}
include:
{%- if pillar.freeipa.client is defined %}
- freeipa.client
{%- endif %}
{%- if pillar.freeipa.server is defined %}
- freeipa.server
{%- endif %}
{%- endif %}
