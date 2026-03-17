{% test has_initial_record(model, business_key, eff_date_column) %}

with violations as (

    select
        {{ business_key }} as BusinessKey
    from {{ model }}
    group by {{ business_key }}
    having
        sum(
            case
                when {{ eff_date_column }} = cast('1900-01-01' as date)
                    then 1
                else 0
            end
        ) = 0
)

select *
from violations

{% endtest %}
