{% macro seq_from_row_number(order_by) -%}
( row_number() over ( order by {{ order_by  }}))
{%- endmacro %}
