//+------------------------------------------------------------------+
//|                    NEWLIFE_Strategies.mqh                        |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Trading strategies implementation                                |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include "NEWLIFE_Constants.mqh"
#include "NEWLIFE_Utilities.mqh"
#include "NEWLIFE_Indicators.mqh"
#include "NEWLIFE_RiskManagement.mqh"

//+------------------------------------------------------------------+
//| Base Strategy Class                                              |
//+------------------------------------------------------------------+
class CBaseStrategy : public IStrategy {
protected:
   // Core properties
   string m_name;                  // Strategy name
   string m_symbol;                // Symbol to trade
   ENUM_TIMEFRAMES m_timeframe;    // Timeframe to analyze
   ENUM_LIQUIDITY_STATE m_liquidityState; // Current market liquidity state
   
   // Indicators and tools
   CIndicatorManager* m_indicators; // Indicator manager
   CRiskManager* m_riskManager;    // Risk manager
   CLogger* m_logger;              // Logger
   
   // Strategy parameters
   double m_minProfitFactor;       // Minimum profit factor to continue trading
   double m_minWinRate;            // Minimum win rate percentage to continue
   double m_riskPercent;           // Risk percentage per trade
   
public:
   // Constructor
   CBaseStrategy(ENUM_LIQUIDITY_STATE liquidityState, string symbol, ENUM_TIMEFRAMES timeframe,
                CIndicatorManager* indicators, CRiskManager* riskManager, CLogger* logger)
      : m_liquidityState(liquidityState), m_symbol(symbol), m_timeframe(timeframe),
        m_indicators(indicators), m_riskManager(riskManager), m_logger(logger) {
      m_name = "BaseStrategy";
      m_minProfitFactor = 1.1;
      m_minWinRate = 50.0;
      m_riskPercent = 1.0;
   }
   
   // IStrategy interface implementation
   virtual bool Initialize() { return true; }
   virtual bool DetectEntrySignal(ENUM_ORDER_TYPE &type) { return false; }
   virtual void CalculateSLTP(ENUM_ORDER_TYPE type, double price, double &sl, double &tp) {}
   virtual double GetPositionSize(ENUM_ORDER_TYPE type, double entryPrice, double stopLoss) { return 0.01; }
   virtual void ManagePosition(ulong ticket) {}
   virtual string GetName() const { return m_name; }
   virtual ENUM_LIQUIDITY_STATE GetLiquidityState() const { return m_liquidityState; }
};

//+------------------------------------------------------------------+
//| XAUUSD Base Strategy Class                                       |
//+------------------------------------------------------------------+
class CXAUUSDBaseStrategy : public CBaseStrategy {
protected:
   // Gold-specific parameters
   double m_slAtrMultiplier;       // Stop Loss ATR multiplier
   double m_tpAtrMultiplier;       // Take Profit ATR multiplier
   int m_atrPeriod;                // ATR period
   int m_minSlPoints;              // Minimum SL distance in points
   
public:
   // Constructor
   CXAUUSDBaseStrategy(ENUM_LIQUIDITY_STATE liquidityState, string symbol, ENUM_TIMEFRAMES timeframe,
                     double slAtrMultiplier = XAUUSD_DEFAULT_SL_ATR_MULTIPLIER, 
                     double tpAtrMultiplier = XAUUSD_DEFAULT_TP_ATR_MULTIPLIER,
                     double riskPercent = 1.0)
      : CBaseStrategy(liquidityState, symbol, timeframe, NULL, NULL, NULL) {
      m_name = "XAUUSD Base Strategy";
      m_slAtrMultiplier = slAtrMultiplier;
      m_tpAtrMultiplier = tpAtrMultiplier;
      m_atrPeriod = 14;
      m_minSlPoints = XAUUSD_MIN_SL_POINTS;
      m_riskPercent = riskPercent;
   }
   
   // Initialize with managers
   virtual bool Initialize(CIndicatorManager* indicators, CRiskManager* riskManager, CLogger* logger) {
      m_indicators = indicators;
      m_riskManager = riskManager;
      m_logger = logger;
      
      if(m_logger) {
         string logMsg = "Initializing " + m_name + " on " + m_symbol + ", " + 
                        EnumToString(m_timeframe) + " timeframe";
         m_logger.Info(logMsg);
      }
      
      return true;
   }
   
   // Calculate stop loss and take profit levels using ATR
   virtual void CalculateSLTP(ENUM_ORDER_TYPE type, double price, double &sl, double &tp) override {
      // Get ATR value
      double atr = m_indicators.GetATR(m_symbol, m_timeframe, m_atrPeriod);
      
      // Calculate SL and TP based on order type
      if(type == ORDER_TYPE_BUY) {
         // For buy orders: SL below entry, TP above entry
         sl = price - (atr * m_slAtrMultiplier);
         tp = price + (atr * m_tpAtrMultiplier);
         
         // Ensure minimum SL distance
         double minSl = price - m_minSlPoints * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         sl = MathMin(sl, minSl);
      }
      else {
         // For sell orders: SL above entry, TP below entry
         sl = price + (atr * m_slAtrMultiplier);
         tp = price - (atr * m_tpAtrMultiplier);
         
         // Ensure minimum SL distance
         double minSl = price + m_minSlPoints * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         sl = MathMax(sl, minSl);
      }
      
      // Log the calculated levels
      if(m_logger) {
         string logMsg = "Calculated SLTP - Entry: " + DoubleToString(price, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) + 
                        ", SL: " + DoubleToString(sl, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) + 
                        ", TP: " + DoubleToString(tp, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) + 
                        ", ATR: " + DoubleToString(atr, 5);
         m_logger.Debug(logMsg);
      }
   }
   
   // Get position size based on risk parameters
   virtual double GetPositionSize(ENUM_ORDER_TYPE type, double entryPrice, double stopLoss) override {
      if(m_riskManager == NULL) return 0.01;
      
      // Use risk manager to calculate position size
      return m_riskManager.CalculatePositionSize(entryPrice, stopLoss, type);
   }
   
   // Check if current trend matches the specified mode
   bool IsTrendMode(ENUM_TREND_MODE trendMode) {
      // Get current trend
      ENUM_TREND_MODE trend = (ENUM_TREND_MODE)m_indicators.GetTrendMode(m_symbol, m_timeframe);
      
      // Check if trend matches the requested mode
      if(trend == TREND_MODE_BULLISH && trendMode == TREND_MODE_BULLISH) {
         return true;
      }
      else if(trend == TREND_MODE_BEARISH && trendMode == TREND_MODE_BEARISH) {
         return true;
      }
      
      return false;
   }
};

//+------------------------------------------------------------------+
//| XAUUSD Breakout Strategy                                         |
//+------------------------------------------------------------------+
class CXAUUSDBreakoutStrategy : public CXAUUSDBaseStrategy {
private:
   // Strategy-specific parameters
   int m_fastEMA;                  // Fast EMA period
   int m_slowEMA;                  // Slow EMA period
   int m_rsiPeriod;                // RSI period
   double m_rsiThresholdUpper;     // RSI upper threshold
   double m_rsiThresholdLower;     // RSI lower threshold
   int m_bollingerPeriod;          // Bollinger Bands period
   double m_bollingerDeviation;    // Bollinger Bands deviation
   
   // Time filtering
   bool m_useTimeFilter;           // Use time filtering flag
   int m_tradingStartHour;         // Trading start hour (server time)
   int m_tradingEndHour;           // Trading end hour (server time)

public:
   // Constructor
   CXAUUSDBreakoutStrategy(ENUM_LIQUIDITY_STATE liquidityState = LIQUIDITY_MEDIUM)
      : CXAUUSDBaseStrategy(liquidityState, "XAUUSD", PERIOD_H1) {
      m_name = "XAUUSD Breakout Strategy";
      
      // Set default parameters
      m_fastEMA = 8;
      m_slowEMA = 21;
      m_rsiPeriod = 14;
      m_rsiThresholdUpper = 70;
      m_rsiThresholdLower = 30;
      m_bollingerPeriod = 20;
      m_bollingerDeviation = 2.0;
      
      // Default time filter: trade during London/NY session
      m_useTimeFilter = true;
      m_tradingStartHour = 8;  // 8 AM server time
      m_tradingEndHour = 17;   // 5 PM server time
   }
   
   // Override initialization to setup indicators
   virtual bool Initialize() override {
      if(!CXAUUSDBaseStrategy::Initialize()) return false;
      
      // Request required indicators
      m_indicators.CreateEMA(m_symbol, m_timeframe, m_fastEMA);
      m_indicators.CreateEMA(m_symbol, m_timeframe, m_slowEMA);
      m_indicators.CreateRSI(m_symbol, m_timeframe, m_rsiPeriod);
      m_indicators.CreateBollingerBands(m_symbol, m_timeframe, m_bollingerPeriod, m_bollingerDeviation);
      m_indicators.CreateATR(m_symbol, m_timeframe, m_atrPeriod);
      
      if(m_logger) {
         string logMsg = "Initialized " + m_name + " with parameters - Fast EMA: " + IntegerToString(m_fastEMA) + 
                        ", Slow EMA: " + IntegerToString(m_slowEMA) + 
                        ", RSI period: " + IntegerToString(m_rsiPeriod);
         m_logger.Info(logMsg);
      }
      
      return true;
   }
   
   // Detect entry signals
   virtual bool DetectEntrySignal(ENUM_ORDER_TYPE &type) override {
      // Check time filter if enabled
      if(m_useTimeFilter) {
         MqlDateTime dt;
         TimeCurrent(dt);
         
         if(dt.hour < m_tradingStartHour || dt.hour >= m_tradingEndHour) {
            // Outside trading hours
            return false;
         }
      }
      
      // Get indicator values
      double fastEMA = m_indicators.GetEMA(m_symbol, m_timeframe, m_fastEMA, 0);
      double slowEMA = m_indicators.GetEMA(m_symbol, m_timeframe, m_slowEMA, 0);
      double rsi = m_indicators.GetRSI(m_symbol, m_timeframe, m_rsiPeriod, 0);
      double bbUpper = m_indicators.GetBollingerBandsUpper(m_symbol, m_timeframe, m_bollingerPeriod, m_bollingerDeviation, 0);
      double bbLower = m_indicators.GetBollingerBandsLower(m_symbol, m_timeframe, m_bollingerPeriod, m_bollingerDeviation, 0);
      double bbMiddle = m_indicators.GetBollingerBandsMiddle(m_symbol, m_timeframe, m_bollingerPeriod, 0);
      
      // Get current close price
      double close = iClose(m_symbol, m_timeframe, 0);
      double prev_close = iClose(m_symbol, m_timeframe, 1);
      
      // Check for bullish breakout signal
      if(fastEMA > slowEMA && 
         close > bbUpper && 
         prev_close <= bbUpper && 
         rsi < m_rsiThresholdUpper) {
         type = ORDER_TYPE_BUY;
         
         if(m_logger) {
            string logMsg = "Detected BUY signal - Fast EMA: " + DoubleToString(fastEMA, 2) + 
                         " > Slow EMA: " + DoubleToString(slowEMA, 2) + 
                         ", Price: " + DoubleToString(close, 2) + 
                         " > BB Upper: " + DoubleToString(bbUpper, 2) + 
                         ", RSI: " + DoubleToString(rsi, 2);
            m_logger.Info(logMsg);
         }
         
         return true;
      }
      
      // Check for bearish breakout signal
      if(fastEMA < slowEMA && 
         close < bbLower && 
         prev_close >= bbLower && 
         rsi > m_rsiThresholdLower) {
         type = ORDER_TYPE_SELL;
         
         if(m_logger) {
            string logMsg = "Detected SELL signal - Fast EMA: " + DoubleToString(fastEMA, 2) + 
                         " < Slow EMA: " + DoubleToString(slowEMA, 2) + 
                         ", Price: " + DoubleToString(close, 2) + 
                         " < BB Lower: " + DoubleToString(bbLower, 2) + 
                         ", RSI: " + DoubleToString(rsi, 2);
            m_logger.Info(logMsg);
         }
         
         return true;
      }
      
      // No signal detected
      return false;
   }
   
   // Position management
   virtual void ManagePosition(ulong ticket) override {
      if(!PositionSelectByTicket(ticket)) return;
      
      // Check position type
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                           SymbolInfoDouble(m_symbol, SYMBOL_BID) : 
                           SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      
      // Calculate profit in points
      double pointSize = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double profitPoints = (posType == POSITION_TYPE_BUY) ? 
                           (currentPrice - openPrice) / pointSize : 
                           (openPrice - currentPrice) / pointSize;
      
      // Get ATR value
      double atr = m_indicators.GetATR(m_symbol, m_timeframe, m_atrPeriod);
      double atrPoints = atr / pointSize;
      
      // Get SL/TP levels
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      
      // Trailing stop logic
      if(profitPoints > atrPoints * m_slAtrMultiplier * 1.5) {
         // Move SL to breakeven + small buffer
         double newSL = 0;
         
         if(posType == POSITION_TYPE_BUY) {
            newSL = openPrice + (atr * 0.5); // Breakeven + buffer
            if(newSL > sl && newSL < currentPrice) {
               // Only move SL if new value is better and not crossed
               if(OrderModify(ticket, 0, newSL, tp, 0)) {
                  if(m_logger) {
                     string logMsg = "Moved BUY SL to breakeven+ at " + DoubleToString(newSL, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
                     m_logger.Info(logMsg);
                  }
               }
            }
         }
         else {
            newSL = openPrice - (atr * 0.5); // Breakeven + buffer
            if(newSL < sl && newSL > currentPrice) {
               // Only move SL if new value is better and not crossed
               if(OrderModify(ticket, 0, newSL, tp, 0)) {
                  if(m_logger) {
                     string logMsg = "Moved SELL SL to breakeven+ at " + DoubleToString(newSL, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
                     m_logger.Info(logMsg);
                  }
               }
            }
         }
      }
      
      // Partial profit taking logic
      // Not implemented in this version
   }
};

//+------------------------------------------------------------------+
//| XAUUSD Range Strategy                                            |
//+------------------------------------------------------------------+
class CXAUUSDRangeStrategy : public CXAUUSDBaseStrategy {
private:
   // Strategy-specific parameters
   int m_rangePeriod;              // Period for range calculation
   double m_rangeThreshold;        // Threshold for range identification
   int m_momPeriod;                // Momentum period
   double m_rangeDeviation;        // Range deviation multiplier
   
public:
   // Constructor
   CXAUUSDRangeStrategy(ENUM_LIQUIDITY_STATE liquidityState = LIQUIDITY_MEDIUM)
      : CXAUUSDBaseStrategy(liquidityState, "XAUUSD", PERIOD_M15) {
      m_name = "XAUUSD Range Strategy";
      
      // Set default parameters
      m_rangePeriod = 48;        // 12 hours (48 periods of M15)
      m_rangeThreshold = 1.2;    // Range/ATR ratio threshold
      m_momPeriod = 14;          // Momentum period
      m_rangeDeviation = 0.8;    // 80% of range width for entries
      
      // Set SL/TP parameters suitable for range trading
      m_slAtrMultiplier = 1.2;
      m_tpAtrMultiplier = 1.5;
   }
   
   // Override initialization to setup indicators
   virtual bool Initialize() override {
      if(!CXAUUSDBaseStrategy::Initialize()) return false;
      
      // Request required indicators
      m_indicators.CreateATR(m_symbol, m_timeframe, m_atrPeriod);
      m_indicators.CreateMomentum(m_symbol, m_timeframe, m_momPeriod);
      
      if(m_logger) {
         string logMsg = "Initialized " + m_name + " with parameters - Range Period: " + 
                        IntegerToString(m_rangePeriod) + ", Range Threshold: " + 
                        DoubleToString(m_rangeThreshold, 2);
         m_logger.Info(logMsg);
      }
      
      return true;
   }
   
   // Check if market is in a range
   bool IsInRange() {
      // Calculate high and low over the range period
      double highestHigh = -DBL_MAX;
      double lowestLow = DBL_MAX;
      
      for(int i = 0; i < m_rangePeriod; i++) {
         double high = iHigh(m_symbol, m_timeframe, i);
         double low = iLow(m_symbol, m_timeframe, i);
         
         if(high > highestHigh) highestHigh = high;
         if(low < lowestLow) lowestLow = low;
      }
      
      // Calculate range width
      double rangeWidth = highestHigh - lowestLow;
      
      // Compare with ATR
      double atr = m_indicators.GetATR(m_symbol, m_timeframe, m_atrPeriod);
      double normalizedRange = rangeWidth / (atr * m_rangePeriod / m_atrPeriod);
      
      // Check if range is tight enough
      return normalizedRange < m_rangeThreshold;
   }
   
   // Detect entry signals
   virtual bool DetectEntrySignal(ENUM_ORDER_TYPE &type) override {
      // First check if we're in a range
      if(!IsInRange()) return false;
      
      // Calculate range boundaries
      double highestHigh = -DBL_MAX;
      double lowestLow = DBL_MAX;
      
      for(int i = 0; i < m_rangePeriod; i++) {
         double high = iHigh(m_symbol, m_timeframe, i);
         double low = iLow(m_symbol, m_timeframe, i);
         
         if(high > highestHigh) highestHigh = high;
         if(low < lowestLow) lowestLow = low;
      }
      
      // Calculate range midpoint and boundaries
      double midpoint = (highestHigh + lowestLow) / 2.0;
      double rangeWidth = highestHigh - lowestLow;
      double upperBoundary = midpoint + (rangeWidth * m_rangeDeviation / 2.0);
      double lowerBoundary = midpoint - (rangeWidth * m_rangeDeviation / 2.0);
      
      // Get current price
      double close = iClose(m_symbol, m_timeframe, 0);
      double prev_close = iClose(m_symbol, m_timeframe, 1);
      
      // Get momentum
      double momentum = m_indicators.GetMomentum(m_symbol, m_timeframe, m_momPeriod, 0);
      double prev_momentum = m_indicators.GetMomentum(m_symbol, m_timeframe, m_momPeriod, 1);
      
      // Check for buy signal (price near lower boundary with improving momentum)
      if(close < lowerBoundary && prev_close <= close &&
         momentum > prev_momentum) {
         type = ORDER_TYPE_BUY;
         
         if(m_logger) {
            string logMsg = "Detected BUY signal in range - Price: " + DoubleToString(close, 2) + 
                         " near lower boundary: " + DoubleToString(lowerBoundary, 2) + 
                         ", Momentum improving: " + DoubleToString(momentum, 2) + 
                         " > " + DoubleToString(prev_momentum, 2);
            m_logger.Info(logMsg);
         }
         
         return true;
      }
      
      // Check for sell signal (price near upper boundary with deteriorating momentum)
      if(close > upperBoundary && prev_close >= close &&
         momentum < prev_momentum) {
         type = ORDER_TYPE_SELL;
         
         if(m_logger) {
            string logMsg = "Detected SELL signal in range - Price: " + DoubleToString(close, 2) + 
                         " near upper boundary: " + DoubleToString(upperBoundary, 2) + 
                         ", Momentum deteriorating: " + DoubleToString(momentum, 2) + 
                         " < " + DoubleToString(prev_momentum, 2);
            m_logger.Info(logMsg);
         }
         
         return true;
      }
      
      // No signal detected
      return false;
   }
   
   // Override SL/TP calculation for range strategy
   virtual void CalculateSLTP(ENUM_ORDER_TYPE type, double price, double &sl, double &tp) override {
      // Calculate range boundaries
      double highestHigh = -DBL_MAX;
      double lowestLow = DBL_MAX;
      
      for(int i = 0; i < m_rangePeriod; i++) {
         double high = iHigh(m_symbol, m_timeframe, i);
         double low = iLow(m_symbol, m_timeframe, i);
         
         if(high > highestHigh) highestHigh = high;
         if(low < lowestLow) lowestLow = low;
      }
      
      // Calculate range midpoint
      double midpoint = (highestHigh + lowestLow) / 2.0;
      
      // Get ATR value for minimum distance
      double atr = m_indicators.GetATR(m_symbol, m_timeframe, m_atrPeriod);
      
      // Calculate SL and TP based on order type
      if(type == ORDER_TYPE_BUY) {
         // For buy orders: SL below entry, TP at midpoint or higher
         sl = price - (atr * m_slAtrMultiplier);
         tp = MathMax(midpoint, price + (atr * m_tpAtrMultiplier));
         
         // Ensure minimum SL distance
         double minSl = price - m_minSlPoints * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         sl = MathMin(sl, minSl);
      }
      else {
         // For sell orders: SL above entry, TP at midpoint or lower
         sl = price + (atr * m_slAtrMultiplier);
         tp = MathMin(midpoint, price - (atr * m_tpAtrMultiplier));
         
         // Ensure minimum SL distance
         double minSl = price + m_minSlPoints * SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         sl = MathMax(sl, minSl);
      }
      
      // Log the calculated levels
      if(m_logger) {
         string logMsg = "Range Strategy SLTP - Entry: " + DoubleToString(price, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) + 
                      ", SL: " + DoubleToString(sl, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) + 
                      ", TP: " + DoubleToString(tp, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) + 
                      ", Range Midpoint: " + DoubleToString(midpoint, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
         m_logger.Debug(logMsg);
      }
   }
   
   // Position management
   virtual void ManagePosition(ulong ticket) override {
      if(!PositionSelectByTicket(ticket)) return;
      
      // Range strategy often uses simpler management - just let SL/TP do their job
      // We could implement time-based exit if price stays in range too long
      
      // Check position duration
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      datetime currentTime = TimeCurrent();
      int positionHours = (int)(currentTime - openTime) / 3600;
      
      // Check if position has been open too long (24+ hours)
      if(positionHours >= 24) {
         // Consider closing the position
         double positionProfit = PositionGetDouble(POSITION_PROFIT);
         
         // If position is profitable, close it
         if(positionProfit > 0) {
            if(m_logger) {
               string logMsg = "Closing range position after " + IntegerToString(positionHours) + 
                            " hours with profit: " + DoubleToString(positionProfit, 2);
               m_logger.Info(logMsg);
            }
            
            // Close position
            // (Implementation depends on your order manager)
         }
      }
   }
};

//+------------------------------------------------------------------+
//| XAUUSD Momentum Strategy                                         |
//+------------------------------------------------------------------+
class CXAUUSDMomentumStrategy : public CXAUUSDBaseStrategy {
private:
   // Strategy-specific parameters
   int m_macdFast;                 // MACD fast EMA period
   int m_macdSlow;                 // MACD slow EMA period
   int m_macdSignal;               // MACD signal period
   int m_adxPeriod;                // ADX period
   double m_adxThreshold;          // ADX threshold for trend strength
   int m_maPeriod;                 // Moving average period
   ENUM_MA_METHOD m_maMethod;      // Moving average method
   
public:
   // Constructor
   CXAUUSDMomentumStrategy(ENUM_LIQUIDITY_STATE liquidityState = LIQUIDITY_MEDIUM)
      : CXAUUSDBaseStrategy(liquidityState, "XAUUSD", PERIOD_H4) {
      m_name = "XAUUSD Momentum Strategy";
      
      // Set default parameters
      m_macdFast = 12;
      m_macdSlow = 26;
      m_macdSignal = 9;
      m_adxPeriod = 14;
      m_adxThreshold = 25.0;
      m_maPeriod = 50;
      m_maMethod = MODE_EMA;
      
      // Set SL/TP parameters suitable for momentum trading
      m_slAtrMultiplier = 2.0;
      m_tpAtrMultiplier = 3.0;
   }
   
   // Override initialization to setup indicators
   virtual bool Initialize() override {
      if(!CXAUUSDBaseStrategy::Initialize()) return false;
      
      // Request required indicators
      m_indicators.CreateMACD(m_symbol, m_timeframe, m_macdFast, m_macdSlow, m_macdSignal);
      m_indicators.CreateADX(m_symbol, m_timeframe, m_adxPeriod);
      m_indicators.CreateMA(m_symbol, m_timeframe, m_maPeriod, m_maMethod);
      m_indicators.CreateATR(m_symbol, m_timeframe, m_atrPeriod);
      
      if(m_logger) {
         string logMsg = "Initialized " + m_name + " with parameters - MACD: " + 
                        IntegerToString(m_macdFast) + "/" + IntegerToString(m_macdSlow) + "/" + 
                        IntegerToString(m_macdSignal) + ", ADX period: " + IntegerToString(m_adxPeriod);
         m_logger.Info(logMsg);
      }
      
      return true;
   }
   
   // Detect entry signals
   virtual bool DetectEntrySignal(ENUM_ORDER_TYPE &type) override {
      // Get indicator values
      double macdMain = m_indicators.GetMACDMain(m_symbol, m_timeframe, m_macdFast, m_macdSlow, m_macdSignal, 0);
      double macdSignal = m_indicators.GetMACDSignal(m_symbol, m_timeframe, m_macdFast, m_macdSlow, m_macdSignal, 0);
      double prevMacdMain = m_indicators.GetMACDMain(m_symbol, m_timeframe, m_macdFast, m_macdSlow, m_macdSignal, 1);
      double prevMacdSignal = m_indicators.GetMACDSignal(m_symbol, m_timeframe, m_macdFast, m_macdSlow, m_macdSignal, 1);
      
      double adx = m_indicators.GetADX(m_symbol, m_timeframe, m_adxPeriod, 0);
      double plusDI = m_indicators.GetPlusDI(m_symbol, m_timeframe, m_adxPeriod, 0);
      double minusDI = m_indicators.GetMinusDI(m_symbol, m_timeframe, m_adxPeriod, 0);
      
      double ma = m_indicators.GetMA(m_symbol, m_timeframe, m_maPeriod, m_maMethod, 0);
      
      // Get current close price
      double close = iClose(m_symbol, m_timeframe, 0);
      
      // Check for bullish momentum signal
      if(prevMacdMain < prevMacdSignal && macdMain > macdSignal &&  // MACD crossover
         close > ma &&                                              // Price above MA
         adx > m_adxThreshold && plusDI > minusDI) {               // Strong bullish trend
         
         type = ORDER_TYPE_BUY;
         
         if(m_logger) {
            string logMsg = "Detected BUY momentum signal - MACD crossover: " + 
                         DoubleToString(macdMain, 5) + " > " + DoubleToString(macdSignal, 5) + 
                         ", ADX: " + DoubleToString(adx, 2) + ", +DI: " + DoubleToString(plusDI, 2) + 
                         ", Price: " + DoubleToString(close, 2) + " > MA: " + DoubleToString(ma, 2);
            m_logger.Info(logMsg);
         }
         
         return true;
      }
      
      // Check for bearish momentum signal
      if(prevMacdMain > prevMacdSignal && macdMain < macdSignal &&  // MACD crossover
         close < ma &&                                              // Price below MA
         adx > m_adxThreshold && plusDI < minusDI) {               // Strong bearish trend
         
         type = ORDER_TYPE_SELL;
         
         if(m_logger) {
            string logMsg = "Detected SELL momentum signal - MACD crossover: " + 
                         DoubleToString(macdMain, 5) + " < " + DoubleToString(macdSignal, 5) + 
                         ", ADX: " + DoubleToString(adx, 2) + ", -DI: " + DoubleToString(minusDI, 2) + 
                         ", Price: " + DoubleToString(close, 2) + " < MA: " + DoubleToString(ma, 2);
            m_logger.Info(logMsg);
         }
         
         return true;
      }
      
      // No signal detected
      return false;
   }
   
   // Position management with trailing stop for momentum strategy
   virtual void ManagePosition(ulong ticket) override {
      if(!PositionSelectByTicket(ticket)) return;
      
      // Check position type
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                           SymbolInfoDouble(m_symbol, SYMBOL_BID) : 
                           SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      
      // Get current SL/TP
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      
      // Get ATR for trailing stop calculation
      double atr = m_indicators.GetATR(m_symbol, m_timeframe, m_atrPeriod);
      
      // Trailing stop logic for momentum strategy - more aggressive trailing
      double newSL = 0;
      bool modifySL = false;
      
      // For buy positions
      if(posType == POSITION_TYPE_BUY) {
         // Calculate trailing stop level
         newSL = currentPrice - atr * m_slAtrMultiplier * 0.7; // Tighter trailing
         
         // Only move SL up
         if(newSL > sl && newSL < currentPrice) {
            modifySL = true;
         }
      }
      // For sell positions
      else {
         // Calculate trailing stop level
         newSL = currentPrice + atr * m_slAtrMultiplier * 0.7; // Tighter trailing
         
         // Only move SL down
         if(newSL < sl && newSL > currentPrice) {
            modifySL = true;
         }
      }
      
      // Modify position if needed
      if(modifySL) {
         if(OrderModify(ticket, 0, newSL, tp, 0)) {
            if(m_logger) {
               string logMsg = "Updated trailing stop for momentum strategy: " + 
                            EnumToString(posType) + " position, New SL: " + 
                            DoubleToString(newSL, (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS));
               m_logger.Info(logMsg);
            }
         }
      }
      
      // Check if momentum is reversing (exit early logic)
      double macdMain = m_indicators.GetMACDMain(m_symbol, m_timeframe, m_macdFast, m_macdSlow, m_macdSignal, 0);
      double macdSignal = m_indicators.GetMACDSignal(m_symbol, m_timeframe, m_macdFast, m_macdSlow, m_macdSignal, 0);
      
      // Early exit if momentum reverses
      if((posType == POSITION_TYPE_BUY && macdMain < macdSignal) ||
         (posType == POSITION_TYPE_SELL && macdMain > macdSignal)) {
         
         // Check if position is profitable
         double profit = PositionGetDouble(POSITION_PROFIT);
         
         if(profit > 0) {
            if(m_logger) {
               string logMsg = "Momentum reversal detected - early exit from profitable " + 
                            EnumToString(posType) + " position, Profit: " + DoubleToString(profit, 2);
               m_logger.Info(logMsg);
            }
            
            // Close position
            // (Implementation depends on your order manager)
         }
      }
   }
};

//+------------------------------------------------------------------+
//| Strategy Factory to create strategies                            |
//+------------------------------------------------------------------+
class CStrategyFactory {
private:
   CLogger* m_logger;
   
public:
   // Constructor
   CStrategyFactory(CLogger* logger = NULL) : m_logger(logger) {}
   
   // Create strategy by name
   IStrategy* CreateStrategy(string strategyName, 
                           CIndicatorManager* indicators, 
                           CRiskManager* riskManager) {
      // Create strategy based on name
      IStrategy* strategy = NULL;
      
      if(strategyName == "XAUUSD_Breakout") {
         strategy = new CXAUUSDBreakoutStrategy(LIQUIDITY_MEDIUM);
      }
      else if(strategyName == "XAUUSD_Range") {
         strategy = new CXAUUSDRangeStrategy(LIQUIDITY_MEDIUM);
      }
      else if(strategyName == "XAUUSD_Momentum") {
         strategy = new CXAUUSDMomentumStrategy(LIQUIDITY_MEDIUM);
      }
      else {
         if(m_logger) {
            string logMsg = "Unknown strategy name: " + strategyName;
            m_logger.Error(logMsg);
         }
         return NULL;
      }
      
      // Initialize strategy
      if(strategy != NULL) {
         // For XAUUSD strategies, we need to call Initialize with managers
         if(CXAUUSDBaseStrategy* xauStrategy = dynamic_cast<CXAUUSDBaseStrategy*>(strategy)) {
            xauStrategy.Initialize(indicators, riskManager, m_logger);
         }
         else {
            strategy.Initialize();
         }
         
         if(m_logger) {
            string logMsg = "Created and initialized strategy: " + strategy.GetName();
            m_logger.Info(logMsg);
         }
      }
      
      return strategy;
   }
};
