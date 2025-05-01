//+------------------------------------------------------------------+
//|                    NEWLIFE_Constants.mqh                         |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Global constants and enumerations                                |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

// Liquidity state enum
enum ENUM_LIQUIDITY_STATE {
   LIQUIDITY_NORMAL,        // Normal market liquidity
   LIQUIDITY_LOW,           // Low liquidity
   LIQUIDITY_MEDIUM,        // Medium liquidity
   LIQUIDITY_HIGH,          // High liquidity
   LIQUIDITY_EXTREME        // Extreme liquidity conditions
};

// Risk profile enum
enum ENUM_RISK_PROFILE {
   RISK_CONSERVATIVE,       // Conservative risk profile
   RISK_BALANCED,           // Balanced risk profile
   RISK_AGGRESSIVE,         // Aggressive risk profile
   RISK_ADAPTIVE            // Adaptive risk profile
};

// Trend direction enum
enum ENUM_TREND_DIRECTION {
   TREND_UP,                // Uptrend
   TREND_DOWN,              // Downtrend
   TREND_NEUTRAL            // Neutral/sideways trend
};

// Trend mode enum
enum ENUM_TREND_MODE {
   TREND_MODE_NEUTRAL,      // Neutral trend
   TREND_MODE_BULLISH,      // Bullish trend
   TREND_MODE_BEARISH       // Bearish trend
};

// Order flow direction enum
enum ENUM_ORDER_FLOW_DIRECTION {
   ORDER_FLOW_BULLISH,      // Bullish order flow
   ORDER_FLOW_BEARISH,      // Bearish order flow
   ORDER_FLOW_NEUTRAL       // Neutral order flow
};

// HFT engine state enum
enum ENUM_HFT_ENGINE_STATE {
   HFT_STATE_INACTIVE,      // Engine inactive
   HFT_STATE_INITIALIZING,  // Engine initializing
   HFT_STATE_MONITORING,    // Monitoring market (not trading)
   HFT_STATE_TRADING,       // Actively trading
   HFT_STATE_COOLDOWN,      // In cooldown period
   HFT_STATE_ERROR          // Error state
};

// HFT strategy types
enum ENUM_HFT_STRATEGY {
   HFT_STRATEGY_TICK_SCALPER,       // Tick-by-tick scalping
   HFT_STRATEGY_VOLATILITY_BREAKOUT, // Volatility breakout
   HFT_STRATEGY_MOMENTUM_BURST,     // Momentum burst
   HFT_STRATEGY_LIQUIDITY_HUNTER,   // Liquidity hunter
   HFT_STRATEGY_SPREAD_CAPTURE,     // Spread capture
   HFT_STRATEGY_ADAPTIVE            // Adaptive (multi-strategy)
};

// XAUUSD specific constants
#define XAUUSD_DEFAULT_SL_ATR_MULTIPLIER   1.5   // Default Stop Loss ATR multiplier for XAUUSD
#define XAUUSD_DEFAULT_TP_ATR_MULTIPLIER   2.5   // Default Take Profit ATR multiplier for XAUUSD
#define XAUUSD_MIN_SL_POINTS               150   // Minimum Stop Loss in points for XAUUSD
#define XAUUSD_MIN_POSITION_VOLUME         0.01  // Minimum position volume for XAUUSD
#define XAUUSD_MAX_POSITION_VOLUME         5.0   // Maximum position volume for XAUUSD
#define XAUUSD_POSITION_VOLUME_STEP        0.01  // Position volume step for XAUUSD

// Forward declarations
// These are declarations to avoid circular references
class IStrategy;
class CIndicatorManager;
class COrderManager;
class CHFTEngine;
class CLogger;
