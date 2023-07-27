// pragma solidity ^0.8.0;

// import "./CakeLpStakingV2Test.sol";
// import "../interfaces/IChainlinkPriceFeed.sol";
// import "../interfaces/IOrderManager.sol";
// import "@openzeppelin/token/ERC20/IERC20.sol";

// struct ShortParams {
//     address OrderManager;
//     address indexTokenChainlink;
//     uint256 leverage;
// }

// contract MarketNeutralV1Test is CakeLpStakingV2Test {
//     using SafeERC20 for IERC20;

//     //short variables
//     address public OrderManager;
//     address public indexTokenChainlink;
//     uint256 public leverage;

//     enum UpdatePositionType {
//         INCREASE,
//         DECREASE
//     }
//     enum Side {
//         LONG,
//         SHORT
//     }

//     constructor(
//         CakePoolParams memory _cakePoolParams, //["0x36696169C63e42cd08ce11f5deeBbCeBae652050","0x556B9306565093C855AEA9AE92A594704c2Cd59e",["0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82","0x55d398326f99059ff775485246999027b3197955"],["0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82","0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"],true,-57260,-57170] -57760,57060 //usdt/bnb
//         CommonAddresses memory _commonAddresses, //["vault","0x13f4EA83D0bd40E75C8222255bc855a974568Dd4","0x46A15B0b27311cedF172AB29E4f4766fbE7F4364"]
//         ShortParams memory _shortParams //["0xf584A17dF21Afd9de84F47842ECEAF6042b1Bb5b","0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE",3]
//     ) CakeLpStakingV2Test(_cakePoolParams, _commonAddresses) {
//         OrderManager = _shortParams.OrderManager;
//         indexTokenChainlink = _shortParams.indexTokenChainlink;
//         leverage = _shortParams.leverage;
//     }

//     function calculateShortAmount(
//         uint256 amount
//     ) internal view virtual returns (uint256 amountShort) {
//         (uint256 amount0Ratio, uint256 amount1Ratio) = assetRatio();
//         if (amount0Ratio == 0) {
//             // amountToken0 = 0;
//             if (isTokenZeroDeposit) {
//                 amountShort = IFullMathLib(fullMathLib).mulDiv(
//                     amount,
//                     1,
//                     1 + leverage
//                 );
//                 // amountToken1 = IFullMathLib(fullMathLib).mulDiv(amount, leverage, 1 + leverage);
//             } else {
//                 amountShort = 0;
//                 // amountToken1 = amount;
//             }
//         } else if (amount1Ratio == 0) {
//             // amountToken1 = 0;
//             if (isTokenZeroDeposit) {
//                 amountShort = 0;
//                 // amountToken0 = amount;
//             } else {
//                 amountShort = IFullMathLib(fullMathLib).mulDiv(
//                     amount,
//                     1,
//                     1 + leverage
//                 );
//                 // amountToken0 = IFullMathLib(fullMathLib).mulDiv(amount, leverage, 1 + leverage);
//             }
//         } else {
//             if (isTokenZeroDeposit) {
//                 amountShort = IFullMathLib(fullMathLib).mulDiv(
//                     amount,
//                     amount1Ratio,
//                     amount1Ratio + leverage * (amount1Ratio + amount0Ratio)
//                 );
//                 // amountToken0 = IFullMathLib(fullMathLib).mulDiv(amount, leverage * amount0Ratio, amount1Ratio + leverage * (amount1Ratio + amount0Ratio));
//                 // amountToken1 = IFullMathLib(fullMathLib).mulDiv(amount, leverage * amount1Ratio, amount1Ratio + leverage * (amount1Ratio + amount0Ratio));
//             } else {
//                 amountShort = IFullMathLib(fullMathLib).mulDiv(
//                     amount,
//                     amount0Ratio,
//                     amount0Ratio + leverage * (amount1Ratio + amount0Ratio)
//                 );
//                 // amountToken0 = IFullMathLib(fullMathLib).mulDiv(amount, amount0Ratio * leverage, amount0Ratio + leverage * (amount1Ratio + amount0Ratio));
//                 // amountToken1 = IFullMathLib(fullMathLib).mulDiv(amount, amount1Ratio * leverage, amount0Ratio + leverage * (amount1Ratio + amount0Ratio));
//             }
//         }
//     }

//     function deposit() public payable {
//         onlyVault();
//         uint256 totalAmount = IERC20(getDepositToken()).balanceOf(
//             address(this)
//         );
//         // uint256 shortAmount = calculateShortAmount(totalAmount);
//         uint256 shortAmount = totalAmount / 7;
//         uint256 price = _getChainlinkPrice();
//         // cakePrice = price/1e4;
//         uint256 sizeChange = _getSizeChange(price, shortAmount);
//         _levelShort(
//             price,
//             shortAmount,
//             sizeChange,
//             UpdatePositionType.INCREASE
//         );
//         // depositV3();
//     }

//     function withdrawShortPosition(
//         uint256 _amount,
//         uint256 _sizeChange,
//         UpdatePositionType _updateType
//     ) public payable {
//         onlyVault();
//         uint256 price = _getChainlinkPrice();
//         _sizeChange = _getSizeChange(price, _amount);
//         _levelShort(price, _amount, _sizeChange, _updateType);

//         // uint256 shortAmount = IERC20(getDepositToken()).balanceOf(
//         //     address(this)
//         // );
//         // //transfer short position to vault
//         // IERC20(getDepositToken()).safeTransfer(vault, shortAmount);
//     }

//     function withdrawResidualBalance() public {
//         onlyVault();
//         _lptoDepositTokenSwap();
//         uint256 depositTokenBal = IERC20(getDepositToken()).balanceOf(
//             address(this)
//         );
//         IERC20(getDepositToken()).safeTransfer(vault, depositTokenBal);
//     }

//     function _levelShort(
//         uint256 _price,
//         uint256 _amount,
//         uint256 _sizeChange,
//         UpdatePositionType _updateType
//     ) internal {
//         require(_amount > 0);
//         bool isIncrease = _updateType == UpdatePositionType.INCREASE;
//         // OrderManager.placeOrder(0, 1, CakeToken, stableCoin, 0, data);
//         if (isIncrease) {
//             IERC20(getDepositToken()).safeApprove(OrderManager, _amount);
//             (bool success, ) = address(OrderManager).call{value: msg.value}(
//                 abi.encodeWithSignature(
//                     "placeOrder(uint8,uint8,address,address,uint8,bytes)",
//                     0,
//                     1,
//                     isTokenZeroDeposit ? lpToken1 : lpToken0,
//                     getDepositToken(),
//                     0,
//                     _getBytesDataIncrease(
//                         _price,
//                         getDepositToken(),
//                         _amount,
//                         _sizeChange
//                     )
//                 )
//             );
//             require(success, "OrderManager placeOrder failed !");
//         } else {
//             (bool success, ) = address(OrderManager).call{value: msg.value}(
//                 abi.encodeWithSignature(
//                     "placeOrder(uint8,uint8,address,address,uint8,bytes)",
//                     1,
//                     1,
//                     isTokenZeroDeposit ? lpToken1 : lpToken0,
//                     getDepositToken(),
//                     0,
//                     _getBytesDataDecrease(
//                         _price,
//                         getDepositToken(),
//                         _sizeChange,
//                         _amount
//                     )
//                 )
//             );
//             require(success, "OrderManager.placeOrder failed");
//         }
//     }

//     function _getBytesDataIncrease(
//         uint256 price,
//         address purchaseToken,
//         uint256 purchaseAmount,
//         uint256 sizeChange
//     ) internal pure returns (bytes memory) {
//         uint256 collateral = purchaseAmount;
//         bytes memory data = abi.encode(
//             price,
//             purchaseToken,
//             purchaseAmount,
//             sizeChange,
//             collateral,
//             bytes("")
//         );
//         return data;
//     }

//     function _getBytesDataDecrease(
//         uint256 price,
//         address payToken,
//         uint256 sizeChange,
//         uint256 collateral
//     ) internal pure returns (bytes memory) {
//         bytes memory data = abi.encode(
//             price,
//             payToken,
//             sizeChange,
//             collateral,
//             bytes("")
//         );
//         return data;
//     }

//     function _getChainlinkPrice() public view returns (uint256) {
//         (, int256 answer, , , ) = IChainlinkPriceFeed(indexTokenChainlink)
//             .latestRoundData();
//         uint256 decimals = IChainlinkPriceFeed(indexTokenChainlink).decimals();
//         return (uint256(answer) * 1e12) / (10 ** decimals);
//     }

//     function _getSizeChange(
//         uint256 price,
//         uint256 collateral
//     ) internal view returns (uint256) {
//         // uint256 cakes = (collateral / price) * leverage;
//         // uint256 cakeInUSD = cakes * price;
//         uint256 sizeChange = collateral * leverage; //multiply here by usdt price
//         return sizeChange * 1e12;
//     }
// }
