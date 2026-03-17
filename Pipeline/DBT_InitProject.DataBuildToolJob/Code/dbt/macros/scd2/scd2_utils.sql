{% macro scd2_default_columns() %}
    EffDate,
    EndDate,
    CurrentFlag
{% endmacro %}


{% macro scd2_detect_changes(columns) %}
    {%- for col in columns %}
        or coalesce(i.{{ col }}, '') <> coalesce(l.{{ col }}, '')
    {%- endfor %}
{% endmacro %}