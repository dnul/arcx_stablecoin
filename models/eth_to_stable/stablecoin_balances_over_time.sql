
{{ config(materialized='table') }}

with transfers as (
    select * from `bigquery-public-data.crypto_ethereum.token_transfers`
    where token_address in (
        --usdc,dai,usdt
        '0x6b175474e89094c44da98b954eedeac495271d0f',
        '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
        '0xdac17f958d2ee523a2206206994597c13d831ec7'
    )
    and block_timestamp>'2017-12-1'
), double_entry_book as (
    -- debits
    select token_address,`from_address` as address, -safe_cast(value as numeric) as value, block_timestamp from transfers
    union all
    -- credits
    select token_address,`to_address` as address, safe_cast(value as numeric) as value, block_timestamp from transfers
),
double_entry_book_grouped_by_date as (
    select token_address, address, sum(value) as balance_increment, date(block_timestamp) as date
    from double_entry_book
    where address in (select distinct(borrower) from {{ref('compound_usdc_sample_address')}})
    group by token_address,address, date
),
daily_balances_with_gaps as (
    select token_address,address, date, sum(balance_increment) over (partition by token_address,address order by date) as balance,
    lead(date, 1, current_date()) over (partition by token_address,address order by date) as next_date
    from double_entry_book_grouped_by_date
),
calendar AS (
    select date from unnest(generate_date_array('2017-12-1', current_date())) as date
),
daily_balances as (
    select token_address, address, calendar.date, balance
    from daily_balances_with_gaps
    join calendar on daily_balances_with_gaps.date <= calendar.date and calendar.date < daily_balances_with_gaps.next_date
)
select token_address,address, date, balance
from daily_balances
order by date desc