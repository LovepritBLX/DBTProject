{% macro cast_to_datetime2_0(expr) %}
case
  when sql_variant_property({{ expr }}, 'BaseType') in ('timestamp','rowversion') then null
  else try_cast({{ expr }} as datetime2(0))
end
{% endmacro %}