{% macro int_date_key_alias(path) -%}
    {%- set parts = path.split('.') -%}
    {%- if parts|length == 1 -%}
(
    YEAR([{{ parts[0] }}]) * 10000
  + MONTH([{{ parts[0] }}]) * 100
  + DAY([{{ parts[0] }}])
)
    {%- else -%}
        {# Tout sauf la dernière partie constitue le préfixe (alias, ou schema.table.alias, etc.) #}
        {%- set prefix = parts[:-1] | join('.') -%}
        {%- set col = parts[-1] -%}
(
    YEAR({{ prefix }}.[{{ col }}]) * 10000
  + MONTH({{ prefix }}.[{{ col }}]) * 100
  + DAY({{ prefix }}.[{{ col }}])
)
    {%- endif -%}
{%- endmacro %}
