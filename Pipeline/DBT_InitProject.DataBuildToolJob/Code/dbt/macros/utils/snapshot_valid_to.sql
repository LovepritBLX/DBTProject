{% macro fabric__snapshot_valid_to() -%}
    cast('2199-12-31' as datetime2(0))
{%- endmacro %}