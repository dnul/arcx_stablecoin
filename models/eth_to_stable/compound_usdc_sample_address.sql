{{ config(materialized='table') }}

-- with borrow_events as (
--     select * FROM `blockchain-etl.ethereum_compound.cUSDC_event_Borrow`  where block_timestamp>'2021-08-01' and block_timestamp<'2021-09-01'
-- ),
-- liquidate_event as (
--     select * from  `blockchain-etl.ethereum_compound.cUSDC_event_LiquidateBorrow`  where block_timestamp>'2021-08-01' and block_timestamp>'2021-09-01'
-- ),
-- -- repayBorrow_event as (
-- --     select * from  `blockchain-etl.ethereum_compound.cUSDC_event_RepayBorrow`  where block_timestamp>'2021-08-01' and block_timestamp>'2021-09-01'
-- -- )
-- select borrow_events.*,
-- case when liquidate_event.borrower is not null then 1 else 0 end as has_liquidate_event
-- from borrow_events  
-- left join liquidate_event on liquidate_event.borrower = borrow_events.borrower
-- order by has_liquidate_event desc


with liquidated_borrows as ( 
    select borrower,block_timestamp from  `blockchain-etl.ethereum_compound.cUSDC_event_LiquidateBorrow`  where block_timestamp>'2021-05-01'
),
borrow_events as (
    select * FROM `blockchain-etl.ethereum_compound.cUSDC_event_Borrow`  where block_timestamp>'2021-05-01'
),
liquidated_borrows_hist as (
    select borrow.*,case when liquidate.block_timestamp is not null then 1 else 0 end as has_liquidate_event,
    row_number() over (partition by borrow.borrower order by borrow.block_timestamp desc) as rk 
    from borrow_events  borrow
    inner join liquidated_borrows liquidate on borrow.borrower=liquidate.borrower and borrow.block_timestamp<liquidate.block_timestamp
),
not_liquidated_borrows as (
    select *,0 as has_liquidate_event,1 as rk FROM borrow_events 
    where borrower not in( select distinct(borrower) from liquidated_borrows_hist)
),
sample_liquidation_dataset as (
    (select * from liquidated_borrows_hist
    where rk=1)
    union all 
    select * from not_liquidated_borrows
)
select * from sample_liquidation_dataset
