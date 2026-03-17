{% macro pascal_case(value) -%}
(
    SELECT STRING_AGG(
               UPPER(LEFT(token, 1)) + LOWER(SUBSTRING(token, 2, 4000)),
               ''
           )
    FROM (
        SELECT LTRIM(RTRIM([value])) AS token
        FROM STRING_SPLIT(
            REPLACE(REPLACE(LTRIM(RTRIM({{ value }})), '_', ' '), '-', ' '),
            ' '
        )
        WHERE LTRIM(RTRIM([value])) <> ''
    ) s
)
{%- endmacro %}
