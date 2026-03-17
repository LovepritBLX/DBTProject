
{%- macro scd_engine00(transformed_cte, kwargs) -%}

{# -------------------------------------------------------------------------
  --Pré-calcul des listes de colonnes
  -- cols0/1/2 : colonnes non qualifiées
  -- sq1/sq2   : colonnes qualifiées staging_quality
  -- prod0/2   : colonnes qualifiées production
-------------------------------------------------------------------------  
#}

{%- set cols0 -%}
  {{ print_columns(kwargs.type_0_cols) }}
{%- endset -%}

{%- set cols1 -%}
  {{ print_columns(kwargs.type_1_cols) }}
{%- endset -%}

{%- set cols2 -%}
  {{ print_columns(kwargs.type_2_cols) }}
{%- endset -%}

{%- set sq1 -%}
  {{ print_columns(kwargs.type_1_cols, 'staging_quality') }}
{%- endset -%}

{%- set sq2 -%}
  {{ print_columns(kwargs.type_2_cols, 'staging_quality') }}
{%- endset -%}

{%- set prod0 -%}
  {{ print_columns(kwargs.type_0_cols, 'production') }}
{%- endset -%}

{%- set prod2 -%}
  {{ print_columns(kwargs.type_2_cols, 'production') }}
{%- endset -%}


{% if kwargs.target_exists %}

current_rows AS (
    SELECT
        {{ kwargs.name }}ScdId,
        {{ kwargs.record_identifier }},
        {{ cols2 }},
        {{ cols0 }}
    FROM {{ kwargs.this }}
    WHERE CurrentFlag = 'Y'
),

type_2_rows AS (
    SELECT
        NULL AS {{ kwargs.name }}Id,
        current_rows.{{ kwargs.name }}ScdId, -- re-use ScdId of current record
        staging_quality.{{ kwargs.record_identifier }},
        'Y' AS CurrentFlag,

        {# Type 0 : prendre staging si current NULL, sinon garder current #}
        {%- for col in kwargs.type_0_cols -%}
          COALESCE(current_rows.{{ col }}, staging_quality.{{ col }}) AS {{ col }}
          {{ ',' if not loop.last or (sq1|trim) or (sq2|trim) }}
        {%- endfor -%}

        {%- if (sq1|trim) -%}
          {{ sq1 }}{{ ',' if (sq2|trim) }}
        {%- endif -%}

        {%- if (sq2|trim) -%}
          {{ sq2 }},
        {%- endif -%}

        cast(getdate() as date) AS EffDate,
        {{ scd_default_end_date() }} AS EndDate
    FROM staging_quality
    LEFT JOIN current_rows
      ON staging_quality.{{ kwargs.record_identifier }} = current_rows.{{ kwargs.record_identifier }}

    {# Détection changement Type 2 #}
    {% if kwargs.type_2_cols | length > 0 %}
    WHERE (
      {% for col in kwargs.type_2_cols %}
        staging_quality.{{ col }} <> current_rows.{{ col }}{{ ' OR' if not loop.last }}{% endfor %}
    )
    {% endif %}
),

updated_production AS (
    SELECT
        production.{{ kwargs.name }}Id,
        production.{{ kwargs.name }}ScdId,
        production.{{ kwargs.record_identifier }},

        CASE
          WHEN type_2_rows.{{ kwargs.record_identifier }} IS NOT NULL THEN 'N'
          ELSE production.CurrentFlag
        END AS CurrentFlag,

        {# Type 0: inchangé #}
        {{ prod0 }}{{ ',' if kwargs.type_0_cols | length > 0 }}

        {# Type 1: prendre staging si présent, sinon garder production #}
        {% for col in kwargs.type_1_cols -%}
          COALESCE(staging_quality.{{ col }}, production.{{ col }}) AS {{ col }},
        {% endfor -%}

        {# Type 2: inchangé dans production (la nouvelle ligne est dans type_2_rows) #}
        {{ prod2 }}{{ ',' if kwargs.type_2_cols | length > 0 }}

        production.EffDate,

        CASE
          WHEN production.CurrentFlag = 'N' THEN production.EndDate
          WHEN type_2_rows.{{ kwargs.record_identifier }} IS NOT NULL
            THEN CAST(dateadd(day, -1, getdate()) as date)
          ELSE production.EndDate
        END AS EndDate

    FROM {{ kwargs.this }} production
    INNER JOIN type_2_rows
      ON production.{{ kwargs.record_identifier }} = type_2_rows.{{ kwargs.record_identifier }}
    LEFT JOIN staging_quality
      ON production.{{ kwargs.record_identifier }} = staging_quality.{{ kwargs.record_identifier }}
),

ready_for_key_assignment AS (
    SELECT *
    FROM (
        SELECT
            {{ kwargs.name }}Id,
            {{ kwargs.name }}ScdId,
            EffDate,
            EndDate,
            CurrentFlag,
            {{ kwargs.record_identifier }},
            {{ cols0 }}{{ ',' if kwargs.type_0_cols | length > 0 }}
            {{ cols1 }}{{ ',' if kwargs.type_1_cols | length > 0 }}
            {{ cols2 }}
        FROM updated_production

        UNION ALL

        SELECT
            {{ kwargs.name }}Id,
            {{ kwargs.name }}ScdId,
            EffDate,
            EndDate,
            CurrentFlag,
            {{ kwargs.record_identifier }},
            {{ cols0 }}{{ ',' if kwargs.type_0_cols | length > 0 }}
            {{ cols1 }}{{ ',' if kwargs.type_1_cols | length > 0 }}
            {{ cols2 }}
        FROM type_2_rows
    ) u
)

{% else %}

ready_for_key_assignment AS (
    SELECT
        NULL as {{ kwargs.name }}Id,
        NULL as {{ kwargs.name }}ScdId,
        {{ kwargs.record_identifier }},

        -- Attributs
        {{ cols2 }}{{ ',' if cols2 }}

        -- Metadata
        {{ cols0 }}{{ ',' if cols0 }}
        {{ cols1 }}{{ ',' if cols1 }}

        -- SCD
        {{ scd_default_effective_date() }} AS EffDate,
        {{ scd_default_end_date() }}       AS EndDate,
        'Y' AS CurrentFlag
    FROM staging_quality
)

{% endif %}

SELECT
    COALESCE(
      {{ kwargs.name }}Id,
      {{ high_water_mark(kwargs.this, kwargs.name ~ 'Id') }} + {{ seq_from_row_number(kwargs.record_identifier) }}
    ) as {{ kwargs.name }}Id,

    COALESCE(
      {{ kwargs.name }}ScdId,
      {{ high_water_mark(kwargs.this, kwargs.name ~ 'Id') }} + {{ seq_from_row_number(kwargs.record_identifier) }}
    ) as {{ kwargs.name }}ScdId,

    {{ kwargs.record_identifier }},
    {{ cols2 }}{{ ',' if cols2 }}
    {{ cols0 }}{{ ',' if cols0 }}
    {{ cols1 }}{{ ',' if cols1 }}
    EffDate,
    EndDate,
    CurrentFlag
FROM ready_for_key_assignment

{%- endmacro -%}