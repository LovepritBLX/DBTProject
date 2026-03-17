
{% macro test_unique_combo(model, combination_of_columns, ignore_nulls=false, where=None) %}

{% set select_parts = [] %}
{% set group_parts  = [] %}
{% set notnull_parts = [] %}

{% for item in combination_of_columns %}
  {% if item is string %}
    {% set expr = adapter.quote(item) %}
    {% set alias = adapter.quote(item) %}
    {% do select_parts.append(expr ~ " AS " ~ alias) %}
    {% do group_parts.append(expr) %}
    {% if ignore_nulls %}{% do notnull_parts.append(expr ~ " IS NOT NULL") %}{% endif %}

  {% elif item is mapping and 'expr' in item and 'alias' in item %}
    {% set expr = item['expr'] %}
    {% set alias = adapter.quote(item['alias']) %}
    {% do select_parts.append(expr ~ " AS " ~ alias) %}
    {% do group_parts.append(expr) %}
    {% if ignore_nulls %}{% do notnull_parts.append(expr ~ " IS NOT NULL") %}{% endif %}

  {% else %}
    {% do exceptions.raise_compiler_error("unique_combo: chaque entrée doit être un string (nom de colonne) OU {'expr','alias'}.") %}
  {% endif %}
{% endfor %}

{% set where_not_null %}
  {% if notnull_parts | length > 0 %}
    AND ( {{ notnull_parts | join(' AND ') }} )
  {% else %} /* no null filter */ {% endif %}
{% endset %}

{% set extra_where %}
  {% if where %} AND ( {{ where }} ) {% else %} /* no extra where */ {% endif %}
{% endset %}

with __base as (
  select
    {{ select_parts | join(',\n    ') }},
    count(*) as _cnt
  from {{ model }}
  where 1=1
    {{ where_not_null }}
    {{ extra_where }}
  group by {{ group_parts | join(', ') }}
  having count(*) > 1
)
select * from __base;
{% endmacro %}