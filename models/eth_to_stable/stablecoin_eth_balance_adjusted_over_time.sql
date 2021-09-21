{{ config(materialized='table') }}

with token_decimals as (
    SELECT address,name,decimals,pow(10, cast(decimals as numeric)) as factor  FROM `bigquery-public-data.crypto_ethereum.amended_tokens` 
    where address in ( select distinct(token_address) from {{ref('stablecoin_balances_over_time')}})
),
usd_adjusted_balances as (
    select stablecoin_balances.*, token_decimals.name, balance/factor as usd_balance from {{ref('stablecoin_balances_over_time')}} as stablecoin_balances inner join 
    token_decimals  on token_decimals.address = stablecoin_balances.token_address
),
total_stablecoin_balance as (
    select address,sum(usd_balance) as stablecoin_usd_balance,date  from usd_adjusted_balances  group by address,date
),
ethereum_usd_balances as (
    select balance.address,balance.date,price.price*balance.balance/pow(10, 18) as eth_usd_balance from {{ref('ethereum_balances_over_time')}} balance
    inner join {{ ref('ethereum_prices')}} price on cast(price.date as DATE) = balance.date
)
select 
    eth_balance.address,
    eth_balance.date,
    sb_balance.stablecoin_usd_balance,
    eth_balance.eth_usd_balance
from ethereum_usd_balances eth_balance left join total_stablecoin_balance sb_balance 
on eth_balance.address=sb_balance.address and eth_balance.date=sb_balance.date