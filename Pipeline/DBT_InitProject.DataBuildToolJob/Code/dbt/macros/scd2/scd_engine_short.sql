{%- macro scd_engine_short(transformed_cte, kwargs) -%}
{% if kwargs.target_exists %}
{% else %}


{%- set cols0 -%}{{ print_columns(kwargs.type_0_cols) }}{%- endset -%}
{%- set cols1 -%}{{ print_columns(kwargs.type_1_cols) }}{%- endset -%}
{%- set cols2 -%}{{ print_columns(kwargs.type_2_cols) }}{%- endset -%}

        SELECT
            0 as {{kwargs.name}}Id, 
            {{date_key(' dbt.current_timestamp()')}} AS effective_date_key,
            99991231 AS expiration_date_key,
            {{kwargs.record_identifier}},
            {{ cols0 }}{{ ',' if cols0 }}
            {{ cols1 }}{{ ',' if cols1 }}
            {{ cols2 }},
            'Y' AS CurrentFlag
        FROM
            staging_quality
{% endif %}

{% endmacro %}