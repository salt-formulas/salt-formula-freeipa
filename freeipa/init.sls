{%- if pillar.freeipa is defined %}
include:
{%- if pillar.freeipa.client is defined %}
- freeipa.client
{%- endif %}
{%- endif %}
