with date_calendar as (
  select
    cast(range as date) as day
  from range(date '2020-09-12', current_date() - interval '1 day', interval '1 day')
),

deal_metrics as (
    select
        cast(sector_start_at as date) as date,
        sum(padded_piece_size_tibs / 1024) as onboarded_data_pibs,
        sum(padded_piece_size_tibs / 1024) filter (piece_client_replication_order = 1 and piece_provider_replication_order = 1) as unique_data_onboarded_data_pibs,
        unique_data_onboarded_data_pibs / onboarded_data_pibs as unique_data_onboarded_data_percentage,
        count(distinct deal_id) as deals,
        count(distinct client_id) as unique_deal_making_clients,
        count(distinct provider_id) as unique_deal_making_providers
    from {{ ref('filecoin_state_market_deals') }}
    where 1 = 1
        and sector_start_at is not null
    group by 1
    order by 1
),

deal_expirations as (
    select
        cast(coalesce(slash_at, end_at) as date) as date,
        count(distinct deal_id) as deal_expirations,
        sum(padded_piece_size_tibs / 1024) as expired_data_pibs
    from {{ ref('filecoin_state_market_deals') }}
    where 1 = 1
        and sector_start_at is not null
    group by 1
    order by 1
),

users_with_active_deals as (
    select
        dc.day,
        sum(padded_piece_size_tibs / 1024) as data_on_active_deals_pibs,
        sum(padded_piece_size_tibs / 1024) filter (piece_client_replication_order = 1 and piece_provider_replication_order = 1) as unique_data_on_active_deals_pibs,
        approx_count_distinct(deals.deal_id) as active_deals,
        approx_count_distinct(deals.client_id) as clients_with_active_deals,
        approx_count_distinct(deals.provider_id) as providers_with_active_deals
    from date_calendar as dc
    left join {{ ref('filecoin_state_market_deals') }} as deals
        on dc.day between deals.sector_start_at and least(deals.end_at, deals.slash_at)
    group by dc.day
),

daily_power as (
    select
        date,
        sum(raw_power_pibs) as raw_power_pibs,
        sum(quality_adjusted_power_pibs) as quality_adjusted_power_pibs,
        sum(verified_data_power_pibs) as verified_data_power_pibs,
    from {{ ref('filecoin_storage_providers_power') }}
    where 1 = 1
    group by 1
    order by 1
),

new_clients as (
    select
        cast(first_deal_at as date) as date,
        coalesce(count(distinct client_id), 0) as new_client_ids
    from {{ ref('filecoin_clients') }}
    group by 1
    order by 1 desc
),

new_providers as (
    select
        cast(first_deal_at as date) as date,
        coalesce(count(distinct provider_id), 0) as new_provider_ids
    from {{ ref('filecoin_storage_providers') }}
    group by 1
    order by 1 desc
)

select
    date_calendar.day as date,
    onboarded_data_pibs,
    unique_data_onboarded_data_pibs,
    unique_data_onboarded_data_percentage,
    data_on_active_deals_pibs,
    unique_data_on_active_deals_pibs,
    deals,
    unique_deal_making_clients,
    unique_deal_making_providers,
    active_deals,
    clients_with_active_deals,
    providers_with_active_deals,
    raw_power_pibs,
    quality_adjusted_power_pibs,
    verified_data_power_pibs,
    data_on_active_deals_pibs / raw_power_pibs as network_utilization_percentage,
    new_client_ids,
    new_provider_ids,
    deal_expirations,
    expired_data_pibs
from date_calendar
left join deal_metrics on date_calendar.day = deal_metrics.date
left join users_with_active_deals on date_calendar.day = users_with_active_deals.day
left join daily_power on date_calendar.day = daily_power.date
left join new_clients on date_calendar.day = new_clients.date
left join new_providers on date_calendar.day = new_providers.date
left join deal_expirations on date_calendar.day = deal_expirations.date
order by date_calendar.day desc
