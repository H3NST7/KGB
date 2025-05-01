# KGB - Gold Trading Expert Advisor for MetaTrader 5

![Version](https://img.shields.io/badge/Version-4.0-brightgreen)
![Platform](https://img.shields.io/badge/Platform-MT5-blue)
![Compatibility](https://img.shields.io/badge/Compatibility-Build%203150+-orange)
![Language](https://img.shields.io/badge/Language-MQL5-yellow)
![License](https://img.shields.io/badge/License-Proprietary-red)

## 🚀 Overview

KGB is an advanced, professional-grade Expert Advisor designed for XAUUSD (Gold) trading on the MetaTrader 5 platform. Powered by the sophisticated NEWLIFE v4.0 core engine, KGB employs multi-strategy adaptation technology that dynamically responds to changing market conditions, providing high-precision entry and exit points with adaptive risk management.

This state-of-the-art trading system combines advanced technical analysis, proprietary liquidity detection, and an optional HFT (High-Frequency Trading) module to deliver exceptional performance across various market regimes—from trending markets to consolidation periods.

## 🌟 Key Features

### 💹 Trading Intelligence
- **Multi-Strategy Engine**: Automatically switches between Breakout, Range, and Momentum strategies based on real-time market conditions
- **Dynamic Market Regime Recognition**: Identifies and adapts to trending, ranging, and volatile market conditions
- **Advanced Liquidity Analysis**: Proprietary algorithms detect and trade optimal liquidity zones
- **Adaptive Entry/Exit Logic**: Fine-tunes entries and exits based on volatility and price action
- **Real-time Strategy Optimization**: Continuously monitors performance metrics and adjusts parameters

### ⚙️ Advanced Technical Framework
- **Modular Architecture**: Highly optimized, component-based design for maximum performance
- **High-Precision Indicators**: Custom-built technical indicators specifically calibrated for XAUUSD
- **Correlation Filters**: Multi-timeframe analysis to confirm trade signals
- **Session-Aware Trading**: Optimizes parameters based on Asian, London, and New York trading sessions
- **Smart HFT Module**: Optional high-frequency trading engine for capturing micro price movements

### 🛡️ Risk Management & Protection
- **Dynamic Position Sizing**: Calculates optimal lot sizes based on account balance and market volatility
- **Adaptive Risk Control**: Automatically reduces exposure during uncertain market conditions
- **Smart Recovery System**: Implements measured recovery strategies after drawdown periods
- **Spread Protection**: Avoids trading during excessive spread conditions
- **Daily Loss Limits**: Customizable daily drawdown limits with automatic shutdown
- **Emergency Protocols**: Built-in safeguards against exceptional market events

## 📋 Requirements

- MetaTrader 5 Terminal (Build 3150 or higher)
- Account with a reputable broker supporting MT5 and XAUUSD trading
- Minimum recommended account balance: $5,000 USD
- Stable internet connection with low latency

## 📊 Performance

KGB is designed for consistent performance across various market conditions, focusing on:

- **Precision Over Frequency**: Quality trades rather than high-volume trading
- **Capital Preservation**: Sophisticated risk management to preserve capital during drawdowns
- **Stable Growth**: Steady equity growth rather than aggressive approaches
- **Adaptability**: Performance maintained across different market regimes

*Note: Past performance does not guarantee future results. Always test thoroughly with your specific broker and risk parameters before live trading.*

## 🔧 Installation

1. Download the KGB EA files from the official source
2. In your MetaTrader 5 terminal, go to **File → Open Data Folder**
3. Navigate to **MQL5 → Experts**
4. Create a new folder named "KGB"
5. Copy all the EA files into the KGB folder:
   - Copy `NEWLIFEV9XAU.mq5` to the main Experts folder
   - Copy all `.mqh` files to the KGB folder
6. Also create an "Include" subfolder inside the KGB folder and copy the corresponding files there
7. Return to MT5 and click **Navigator → Expert Advisors → Refresh**
8. The KGB EA should now appear in your Navigator panel

## ⚙️ Configuration

KGB offers extensive customization through its input parameters. Here are the key sections:

### General Settings
- **Debug Mode**: Enable/disable detailed logging
- **Magic Number**: Unique identifier for this EA instance
- **Order Queue Size**: Buffer size for pending operations

### Risk Management
- **Risk Profile**: Choose between Conservative, Balanced, Aggressive, or Adaptive
- **Base Risk Per Trade**: Default risk percentage per position
- **Maximum Daily Loss**: Threshold for daily drawdown protection
- **Profit Strategy**: Method for profit taking management

### Trade Settings
- **Maximum Trades**: Total and per-day limits
- **Time Between Trades**: Minimum interval between operations
- **Trailing Settings**: Configuration for trailing stop functionality
- **Partial Close**: Settings for partial position management

### Indicator Settings
- **ATR Configuration**: Period and multipliers for volatility measurement
- **Moving Average Settings**: Trend and scalp MA periods and method
- **Oscillator Parameters**: RSI, ADX and other indicator settings

### Session Settings
- **Active Trading Sessions**: Define which market sessions to trade
- **Session Multipliers**: Adjust risk based on session volatility
- **Weekend Avoidance**: Option to avoid trading near market close

### Filter Settings
- **Spread Control**: Maximum allowed spread for trading
- **Correlation Filter**: Use multi-instrument correlation analysis
- **News Filter**: Avoid trading around high-impact economic events
- **Trend Filter**: Trade only in the direction of the main trend

### HFT Engine Settings
- **HFT Enable/Disable**: Turn the high-frequency module on/off
- **HFT Strategy**: Select between different HFT approaches
- **HFT Risk Parameters**: Specialized risk settings for high-frequency operations
- **HFT Performance Metrics**: Targets and limits for the HFT module

## 📈 Recommended Timeframes & Settings

KGB is optimized for trading XAUUSD on the following timeframes:

| Strategy Type | Recommended Timeframes | Market Conditions |
|---------------|------------------------|-------------------|
| Breakout | H1, H4 | High volatility, trending markets |
| Range | M15, M30 | Consolidation, low volatility |
| Momentum | H1, H4 | Strong directional moves |
| HFT | M1, M5 | All conditions with sufficient liquidity |

### Suggested Starting Settings:

#### Conservative Profile
```
Risk Profile = RISK_CONSERVATIVE
Risk Per Trade = 0.5%
Max Daily Loss = 2.0%
ATR Multiplier SL = 2.0
ATR Multiplier TP = 4.0
Enable HFT Engine = false
```

#### Balanced Profile
```
Risk Profile = RISK_BALANCED
Risk Per Trade = 1.0%
Max Daily Loss = 2.5%
ATR Multiplier SL = 1.8
ATR Multiplier TP = 3.5
Enable HFT Engine = false
```

#### Aggressive Profile
```
Risk Profile = RISK_AGGRESSIVE
Risk Per Trade = 1.5%
Max Daily Loss = 3.0%
ATR Multiplier SL = 1.5
ATR Multiplier TP = 3.0
Enable HFT Engine = true
HFT Risk Percent = 0.5%
```

## 💻 Usage Tips

- **Initial Testing**: Start with the Conservative profile on a demo account
- **Optimization**: Adjust the ATR multipliers based on your broker's specific spread and execution
- **Session Settings**: Fine-tune the session multipliers based on when you see the best performance
- **HFT Module**: Only enable after thoroughly testing the main EA and understanding its behavior
- **Monitoring**: Regularly check the EA's performance metrics and logs

## 🛠️ Troubleshooting

| Issue | Solution |
|-------|----------|
| EA not visible in Navigator | Verify file locations and restart MT5 |
| No trades being opened | Check if trading is allowed and spread conditions are met |
| Error messages about indicators | Make sure all include files are properly installed |
| Excessive risk warnings | Review and adjust risk settings to match your account size |
| HFT engine errors | Ensure your broker provides the necessary execution speed |

## 🔄 Update Process

When updating to new versions:
1. Close all open positions managed by the EA
2. Remove the EA from all charts
3. Close MetaTrader 5
4. Replace all files with the new version
5. Restart MetaTrader 5

## 📞 Support

For technical support and inquiries:

- GitHub Issues: Create a new issue in this repository
- Email: support@H3NST7.com
- Website: [www.H3NST7.com](https://www.H3NST7.com)

## ⚠️ Risk Disclaimer

Trading XAUUSD (Gold) involves substantial risk of loss and is not suitable for all investors. Past performance is not indicative of future results. The high degree of leverage that is often obtainable in commodity trading can work against you as well as for you. The use of leverage can lead to large losses as well as gains. This Expert Advisor is a sophisticated trading tool that requires proper understanding of the gold market and trading principles.

**IMPORTANT**: Before deploying this EA on a live account, ensure you:
1. Thoroughly test it on a demo account
2. Understand all parameters and their effects
3. Start with conservative settings
4. Never risk money you cannot afford to lose

## 📜 License & Copyright

© 2025 H3NST7 (www.H3NST7.com). All Rights Reserved.

This software is proprietary and provided under license. Unauthorized copying, modification, distribution, or use of this software is strictly prohibited.

---

**NEWLIFE v4.0 Engine - Powered by Advanced Machine Learning and Statistical Analysis**
