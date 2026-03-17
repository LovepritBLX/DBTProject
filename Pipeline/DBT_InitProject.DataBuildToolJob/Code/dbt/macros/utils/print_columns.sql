{% macro print_columns(cols, prefix='') -%}
{%- for col in cols -%}
{{ prefix ~ '.' if prefix }}{{ col }}{{ ',' if not loop.last }}
{%- endfor -%}
{% endmacro %}
