
**Abstract**

Delta-neutral CLMM strategy on PancakeSwap v3

Our product allows fund managers to launch their delta-neutral farming vault using LP pools on PancakeSwap v3.

Fund managers can actively manage their concentrated positions to earn yield in USDT while hedging the risk of volatile assets on Level Finance (a BNB-based decentralised perpetual protocol).

The rewards are harvested algorithmically to maximize strategy efficiency. Asset rebalancing is triggered on a threshold to maintain hedge neutrality.

Automations are built with Gelato.

![Flowchart](https://rivera.money/assets/images/flowChart.png)

**Strategy**

Users enter the strategy with USDT. USDT enters our vault contract and then moves to the strategy contract.

Once our assets reach the strategy contract, they are allocated to Pancakeswap LP and Level Finance in a certain ratio depending upon the fund manager's input parameters.

The ratio of an optimum CLMM LP depends on the input parameters including the minimum range, the maximum range, and the current price of USDT/BNB. Leverage input from the fund manager determines the ratio of the assets allocation to the long side (Pancakeswap) and the short side (Level Finance).

These calculations are done by the strategy contract and the USDT is deployed accordingly.

Our gelato automation ensures that the process's CAKE rewards are compounded back into the strategy optimally.

Rebalancing of LP positions is done by fund manager frequently to ensure that they are not going out of range. Delta-neutral rebalancing of BNB position is done by gelato automation to ensure that the asset always remains neutral.
