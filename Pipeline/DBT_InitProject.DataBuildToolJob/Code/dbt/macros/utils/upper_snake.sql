{% macro upper_snake(value) -%}
(UPPER(REPLACE(LTRIM(RTRIM({{ value }})), ' ', '_' ) ))
{%- endmacro %}
