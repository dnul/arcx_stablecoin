# Arcx feature generation

The objective of this project is to generate a general purpose feature or  index that can be used for different use cases within arcx. 


# Initial hypothesis

I'd like to explore the effect of having / not having stablecoins stored in a wallet as a protection to fluctuations in the market. 

`are wallets which hold a good non-volatile (e.g stablecoins) / volatile asset relation less propense to liquidation events? `


to answer this question we would need to calculate the `volatile` assets balances in a wallet across time along with the `non-volatile`.  This might be too complex to come by for the scope of this project, instead I propose a `proxy` index to analyze this hypothesis:

` stablecoin_to_eth_ratio = ETH_USD / STABLE_USD `

where: 
* `STABLE_USD = DAI+USDC+USDT`  
* `ETH_USD = ETH_VALUE*ETH_PRICE_USD` 

in representation of volatile assets we only consider ETH. We established an initial threshold or operating boundaries for the index, meaning it  would only apply when the following condition holds
```
 ETH_USD>=100 and STABLE_USD>=100
```


The repurposed hypothesis would then be that if you hold a fair amount of stablecoins to support your ETH ( **high stablecoin_to_eth_ratio**) then you have a more robust position against market fluctuations and therefore are less likely to have liquidation events. (** see caveats section **)

# Sample data

using the `blockchain-etl.ethereum_compound` dataset available in bigquery, I sampled some `borrow` and `liquidate` events from the compound protocol. We calculate the index only in this subset of addresses to reduce the workload and also to get more insights in a real scenario.

# Pipeline

to calculate this index we process a few datasets from biguqery and using external APIs:

  * ERC20 transfers to asses usdc,dai,usdt balances over time
  * Ethereum transfers and fees to asses eth over time
  * Ethereum prices per date to combine with ethereum balances

I leverage DBT to run the pipeline,  the model queries can be found under **models/eth_to_stable**. 

It is worth noting that both `ethereum_balances_over_time` and `stablecoin_balance_over_time` could be used as standalone indexes in other contexts. 

# Indexes

the table `supple-antenna-326401.arcx_dev.eth_to_stable_index` has view access enabled for allUsers so you should be able to query it in your bq connsole. 
```
COLUMN  TYPE
address	STRING
date	DATE
stablecoin_usd_balance	NUMERIC	
eth_usd_balance	FLOAT	
eth_to_stablecoin_ratio	FLOAT	
```
* *eth_to_stablecoin_ratio*: holds the value of the index explained in the section above across different dates.
* *eth_usd_balance* : is the eth balance in usd value across lifetime of the wallet
* *stablecoin_usd_balance* : is the usd balance of all (usdc+dai+usdt) stablecoins combined across the lifetime of the wallet.


regardless of the proposed index the last two indices should be useful for many problems and a lot other features could be derived from them.

# Using dbt

You can use the dbt models and generate this and intermediate datasets by running

```dbt seed && dbt run```

you'll need to setup a project in bigquery first since it relies on public datasets on that platform.

# Analysis

we explore the results in the notebook

# Caveats

* ETH might not be representative of the value of volatile assets. Addresses might contain several other tokens that accrue more value and are not captured by this approach
* Representing stablecoin by using usdc+dai+usdt might miss some other cases such as cDAI,Paxos or other assets and even having such assets in an exchange or other address.

# Further work
There are so many paths to go from here, i'll just list a few

* calculating total value for wallet across time considering all erc20 tokens and re-calculate ratio against stable assets.
* expand address base to sample the index on more wallets. 
* aggregate all three indexes into different time-windows to detect trends,spikes or relative growth to engineer new features. 
* sample data from other lending protcols to further validate predictive power of index
