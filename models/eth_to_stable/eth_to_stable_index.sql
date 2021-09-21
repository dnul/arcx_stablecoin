{{ config(materialized='table') }}

select *,
case 
    when eth_usd_balance is NULL or stablecoin_usd_balance is NULL then NULL
    when eth_usd_balance<100 or stablecoin_usd_balance<100 then NULL -- if not enough balance on either STABLE or ETH then ignore this feature
    else stablecoin_usd_balance*1.0/eth_usd_balance
end as eth_to_stablecoin_ratio
from {{ref('stablecoin_eth_balance_adjusted_over_time')}} 