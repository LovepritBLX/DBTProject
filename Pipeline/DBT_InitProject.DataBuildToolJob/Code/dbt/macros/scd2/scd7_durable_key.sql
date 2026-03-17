{% macro scd7_durable_key(natural_key_cols, dim_id_col='dim_id', valid_from_col='EffDate') %}
 {# natural_key_cols: liste de colonnes (strings), ex: ['customer_code'] ou ['source_system','customer_code'] #}
 {% if natural_key_cols is string %}
   {% set nk = [natural_key_cols] %}
 {% else %}
   {% set nk = natural_key_cols %}
 {% endif %}
 FIRST_VALUE({{ dim_id_col }}) OVER (
   PARTITION BY
     {%- for c in nk -%}
       {{ c }}{{ ", " if not loop.last }}
     {%- endfor -%}
   ORDER BY {{ valid_from_col }} ASC, {{ dim_id_col }} ASC
   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
 )
{% endmacro %}