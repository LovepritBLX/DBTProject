{% macro int_date_key(date_value) %}
( year({{ date_value }}) * 10000 + month({{ date_value }}) * 100 + day({{ date_value }}))
{% endmacro %}
