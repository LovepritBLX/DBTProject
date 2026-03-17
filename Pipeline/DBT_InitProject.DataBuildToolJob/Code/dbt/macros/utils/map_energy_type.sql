{% macro map_energy_type(column_name) %}
    {%- set clean_col = column_name | replace("'", "") -%}
    case
        when {{ clean_col }} = 'Hydro' then 'Hydropower'
        when {{ clean_col }} = 'PV' then 'Solar'
        when {{ clean_col }} = 'BESS' then 'Storage'
        when {{ clean_col }} is null then 'Unknown'
        else   {{ clean_col }}
    end
{% endmacro %}
