//+------------------------------------------------------------------+
//|                    NEWLIFE_Compiler.mqh                          |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Interface definitions and primary compiler directives            |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

// Include constants file first
#include "NEWLIFE_Constants.mqh"

// Forward declaration for CIndicatorManager
class CIndicatorManager;

//+------------------------------------------------------------------+
//| Interfaces                                                       |
//+------------------------------------------------------------------+

// Don't redefine IStrategy if already defined in Constants.mqh
#ifndef ISTRATEGY_DEFINED
#define ISTRATEGY_DEFINED

// Strategy interface
class IStrategy {
public:
   // Fixed destructor tag mismatch by using proper syntax
   virtual ~IStrategy(void) {}
   
   // Core methods required for all strategies
   virtual bool Initialize() = 0;
   virtual bool DetectEntrySignal(ENUM_ORDER_TYPE &type) = 0;
   virtual void CalculateSLTP(ENUM_ORDER_TYPE type, double price, double &sl, double &tp) = 0;
   virtual double GetPositionSize(ENUM_ORDER_TYPE type, double entryPrice, double stopLoss) = 0;
   virtual void ManagePosition(ulong ticket) = 0;
   virtual string GetName() const = 0;
   virtual ENUM_LIQUIDITY_STATE GetLiquidityState() const = 0;
};
#endif // ISTRATEGY_DEFINED

//+------------------------------------------------------------------+
//| Optimizer classes                                                |
//+------------------------------------------------------------------+

// XAUUSD specific optimizer
class XAUUSDOptimizer {
private:
   double m_timeMultipliers[24];    // Hour-based multipliers
   double m_volatilityFactor;       // Current market volatility factor
   bool m_initialized;              // Initialization flag
   
public:
   XAUUSDOptimizer() : m_volatilityFactor(1.0), m_initialized(false) {
      // Default constructor initializes time multipliers
      for(int i = 0; i < 24; i++) {
         m_timeMultipliers[i] = 1.0;
      }
      
      // Inactive hours
      m_timeMultipliers[0] = 0.7;
      m_timeMultipliers[1] = 0.6;
      m_timeMultipliers[2] = 0.5;
      m_timeMultipliers[3] = 0.5;
      
      // Asian session (higher volatility)
      m_timeMultipliers[4] = 0.8;
      m_timeMultipliers[5] = 0.9;
      m_timeMultipliers[6] = 1.0;
      m_timeMultipliers[7] = 1.1;
      
      // London open (high volatility)
      m_timeMultipliers[8] = 1.3;
      m_timeMultipliers[9] = 1.2;
      m_timeMultipliers[10] = 1.1;
      m_timeMultipliers[11] = 1.0;
      
      // NY open (high volatility)
      m_timeMultipliers[12] = 1.4;
      m_timeMultipliers[13] = 1.3;
      m_timeMultipliers[14] = 1.2;
      m_timeMultipliers[15] = 1.1;
      
      // NY/London overlap (highest volatility)
      m_timeMultipliers[16] = 1.2;
      m_timeMultipliers[17] = 1.1;
      m_timeMultipliers[18] = 1.0;
      m_timeMultipliers[19] = 0.9;
      
      // Evening session (lower volatility)
      m_timeMultipliers[20] = 0.8;
      m_timeMultipliers[21] = 0.7;
      m_timeMultipliers[22] = 0.6;
      m_timeMultipliers[23] = 0.5;
   }
   
   bool Initialize() {
      m_initialized = true;
      return true;
   }
   
   // Check if current time is optimal for trading
   bool IsOptimalTradingTime() const {
      if(!m_initialized) return false;
      
      MqlDateTime time;
      TimeToStruct(TimeGMT(), time);
      
      int hour = time.hour;
      
      // Avoid trading near market close on Friday
      if(time.day_of_week == 5 && hour >= 20) {
         return false;
      }
      
      // Time-based optimization - avoid low multiplier times
      if(m_timeMultipliers[hour] < 0.7) {
         return false;
      }
      
      return true;
   }
   
   // Get optimal ATR multiplier adjusted for current conditions
   double GetOptimalATRMultiplier(double baseMultiplier) const {
      if(!m_initialized) return baseMultiplier;
      
      MqlDateTime time;
      TimeToStruct(TimeGMT(), time);
      
      int hour = time.hour;
      
      // Adjust ATR multiplier based on time and volatility
      return baseMultiplier * m_timeMultipliers[hour] * m_volatilityFactor;
   }
   
   // Get optimal risk multiplier
   double GetOptimalRiskMultiplier() const {
      if(!m_initialized) return 1.0;
      
      MqlDateTime time;
      TimeToStruct(TimeGMT(), time);
      
      int hour = time.hour;
      double multiplier = m_timeMultipliers[hour];
      
      // Reduce risk in very low or high volatility periods
      if(m_volatilityFactor < 0.7 || m_volatilityFactor > 1.3) {
         multiplier *= 0.7;
      }
      
      return multiplier;
   }
};
