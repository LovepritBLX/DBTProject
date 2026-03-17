{% macro high_water_mark(target_relation, id_column) -%}
  {%- if is_incremental() -%}
    (select coalesce(nullif(max({{ id_column }} ), -1), 0) from {{ target_relation }})
  {%- else -%}
    0
  {%- endif -%}
{%- endmacro %}
