//+------------------------------------------------------------------+
//|                    NEWLIFE_RiskManagement.mqh                    |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Risk management system for trading                               |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include "NEWLIFE_Constants.mqh"

//+------------------------------------------------------------------+
//| Risk Manager Class                                               |
//+------------------------------------------------------------------+
class CRiskManager {
private:
   // Configuration
   double m_baseRiskPercent;
   double m_maxDailyLoss;
   ENUM_RISK_PROFILE m_riskProfile;
   
   // Dynamic risk adjustments
   double m_currentRiskMultiplier;
   
   // Account metrics
   double m_balance;
   double m_equity;
   double m_dailyLoss;
   int m_consecutiveLosses;
   
   // Recovery tracking
   bool m_inRecoveryMode;
   double m_recoveryFactor;
   
   // Risk caps
   double m_maxRiskPerTrade;
   double m_maxPositionSize;
   
   // Private methods
   void AdjustRiskMultiplier();
   
public:
   // Constructor
   CRiskManager(double baseRiskPercent = 1.0, double maxDailyLoss = 2.0, 
               ENUM_RISK_PROFILE riskProfile = RISK_BALANCED);
   
   // Initialize the risk manager
   bool Initialize();
   
   // Update account metrics
   void UpdateMetrics(double balance, double equity, double dailyLoss, int consecutiveLosses);
   
   // Calculate risk-adjusted position size
   double CalculatePositionSize(string symbol, double entryPrice, double stopLoss);
   
   // Risk factor calculation
   double GetRiskFactor();
   
   // Check if trading should be allowed based on risk parameters
   bool IsTradingAllowed();
   
   // Recovery mode management
   void EnterRecoveryMode(double factor = 0.7);
   void ExitRecoveryMode();
   bool IsInRecoveryMode() const { return m_inRecoveryMode; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(double baseRiskPercent, double maxDailyLoss, 
                         ENUM_RISK_PROFILE riskProfile) {
   m_baseRiskPercent = baseRiskPercent;
   m_maxDailyLoss = maxDailyLoss;
   m_riskProfile = riskProfile;
   
   m_currentRiskMultiplier = 1.0;
   m_inRecoveryMode = false;
   m_recoveryFactor = 0.7;
   
   m_balance = 0.0;
   m_equity = 0.0;
   m_dailyLoss = 0.0;
   m_consecutiveLosses = 0;
   
   m_maxRiskPerTrade = 2.0; // Maximum 2% risk per trade
   m_maxPositionSize = 0.0; // Will be calculated in Initialize
}

//+------------------------------------------------------------------+
//| Initialize the risk manager                                      |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize() {
   // Get initial account metrics
   m_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   m_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   // Set maximum position size based on account
   double accountSize = m_balance;
   
   if(accountSize < 1000.0) {
      m_maxPositionSize = 0.1; // Micro account
   } else if(accountSize < 10000.0) {
      m_maxPositionSize = 1.0; // Mini account
   } else if(accountSize < 50000.0) {
      m_maxPositionSize = 5.0; // Standard account
   } else {
      m_maxPositionSize = 10.0; // Professional account
   }
   
   // Adjust risk profile based on account size
   if(accountSize < 2000.0 && m_riskProfile == RISK_AGGRESSIVE) {
      // Smaller accounts shouldn't use aggressive risk
      m_riskProfile = RISK_BALANCED;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Update metrics with current account data                         |
//+------------------------------------------------------------------+
void CRiskManager::UpdateMetrics(double balance, double equity, double dailyLoss, 
                               int consecutiveLosses) {
   m_balance = balance;
   m_equity = equity;
   m_dailyLoss = dailyLoss;
   m_consecutiveLosses = consecutiveLosses;
   
   // Check if recovery mode should be activated
   if(m_dailyLoss > m_maxDailyLoss * 0.7 || m_consecutiveLosses >= 3) {
      if(!m_inRecoveryMode) {
         EnterRecoveryMode();
      }
   } else if(m_inRecoveryMode && m_dailyLoss < m_maxDailyLoss * 0.3 && m_consecutiveLosses == 0) {
      // Exit recovery mode when conditions improve
      ExitRecoveryMode();
   }
   
   // Adjust risk multiplier based on current metrics
   AdjustRiskMultiplier();
}

//+------------------------------------------------------------------+
//| Calculate position size based on risk parameters                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePositionSize(string symbol, double entryPrice, double stopLoss) {
   // Validate inputs
   if(entryPrice <= 0.0 || stopLoss <= 0.0) {
      Print("Invalid price inputs for risk calculation");
      return 0.01; // Minimum size
   }
   
   // Get risk amount
   double riskPercent = m_baseRiskPercent * m_currentRiskMultiplier;
   
   // Cap risk percent at maximum
   if(riskPercent > m_maxRiskPerTrade) {
      riskPercent = m_maxRiskPerTrade;
   }
   
   double riskAmount = m_balance * (riskPercent / 100.0);
   
   // Calculate stop loss distance in points
   double slDistance = MathAbs(entryPrice - stopLoss);
   
   // Symbol-specific position sizing
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double pointValue = tickValue / tickSize;
   
   // Calculate position size
   double positionSize = 0.0;
   
   if(slDistance > 0.0 && pointValue > 0.0) {
      double slPoints = slDistance / SymbolInfoDouble(symbol, SYMBOL_POINT);
      positionSize = riskAmount / (slPoints * pointValue);
   } else {
      Print("Invalid values for position sizing");
      return 0.01; // Minimum size
   }
   
   // Normalize to lot constraints
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = MathMin(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX), m_maxPositionSize);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   positionSize = MathFloor(positionSize / lotStep) * lotStep;
   positionSize = MathMax(minLot, MathMin(positionSize, maxLot));
   
   return positionSize;
}

//+------------------------------------------------------------------+
//| Get current risk factor for position sizing                      |
//+------------------------------------------------------------------+
double CRiskManager::GetRiskFactor() {
   return m_currentRiskMultiplier;
}

//+------------------------------------------------------------------+
//| Check if trading should be allowed based on risk limits          |
//+------------------------------------------------------------------+
bool CRiskManager::IsTradingAllowed() {
   // Check daily loss limit
   if(m_dailyLoss >= m_maxDailyLoss) {
      Print("Daily loss limit reached: ", DoubleToString(m_dailyLoss, 2), 
            "% > ", DoubleToString(m_maxDailyLoss, 2), "%");
      return false;
   }
   
   // Check equity protection
   if(m_equity < m_balance * 0.9) {
      Print("Equity protection triggered: ", DoubleToString(m_equity, 2), 
            " < 90% of balance ", DoubleToString(m_balance, 2));
      return false;
   }
   
   // Advanced checks based on risk profile
   switch(m_riskProfile) {
      case RISK_CONSERVATIVE:
         {
         // More conservative risk checks
         if(m_dailyLoss > m_maxDailyLoss * 0.7 || m_consecutiveLosses >= 2) {
            return false;
         }
         }
         break;
         
      case RISK_BALANCED:
         {
         // Balanced risk checks
         if(m_dailyLoss > m_maxDailyLoss * 0.85 || m_consecutiveLosses >= 3) {
            return false;
         }
         }
         break;
         
      case RISK_AGGRESSIVE:
         {
         // Aggressive risk profile still respects main limits
         if(m_dailyLoss > m_maxDailyLoss * 0.95 || m_consecutiveLosses >= 4) {
            return false;
         }
         }
         break;
         
      case RISK_ADAPTIVE:
         {
         // Adaptive profile uses dynamic checks
         double threshold = 0.8;
         if(m_consecutiveLosses > 0) {
            threshold -= (m_consecutiveLosses * 0.1); // Reduce threshold with each loss
         }
         
         if(m_dailyLoss > m_maxDailyLoss * threshold) {
            return false;
         }
         }
         break;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Enter recovery mode with reduced risk                            |
//+------------------------------------------------------------------+
void CRiskManager::EnterRecoveryMode(double factor) {
   if(!m_inRecoveryMode) {
      m_inRecoveryMode = true;
      m_recoveryFactor = factor;
      
      // Apply recovery factor to risk multiplier
      double prevMultiplier = m_currentRiskMultiplier;
      m_currentRiskMultiplier *= m_recoveryFactor;
      
      Print("Entering recovery mode: Risk multiplier reduced from ", 
            DoubleToString(prevMultiplier, 2), " to ", 
            DoubleToString(m_currentRiskMultiplier, 2));
   }
}

//+------------------------------------------------------------------+
//| Exit recovery mode and return to normal risk                     |
//+------------------------------------------------------------------+
void CRiskManager::ExitRecoveryMode() {
   if(m_inRecoveryMode) {
      m_inRecoveryMode = false;
      
      // Restore risk multiplier
      m_currentRiskMultiplier /= m_recoveryFactor;
      
      Print("Exiting recovery mode: Risk multiplier restored to ", 
            DoubleToString(m_currentRiskMultiplier, 2));
   }
}

//+------------------------------------------------------------------+
//| Adjust risk multiplier based on metrics                          |
//+------------------------------------------------------------------+
void CRiskManager::AdjustRiskMultiplier() {
   // Start with base multiplier (possibly modified by recovery mode)
   double baseMultiplier = m_inRecoveryMode ? (1.0 * m_recoveryFactor) : 1.0;
   
   // Adjust based on risk profile
   switch(m_riskProfile) {
      case RISK_CONSERVATIVE:
         baseMultiplier *= 0.8;
         break;
         
      case RISK_BALANCED:
         // No adjustment for balanced profile
         break;
         
      case RISK_AGGRESSIVE:
         baseMultiplier *= 1.2;
         break;
         
      case RISK_ADAPTIVE:
         // Dynamic adjustment based on performance
         if(m_consecutiveLosses > 0) {
            // Reduce risk after consecutive losses
            baseMultiplier *= (1.0 - (0.1 * m_consecutiveLosses));
         } else if(m_equity > m_balance * 1.05) {
            // Increase risk when performing well
            baseMultiplier *= 1.1;
         }
         break;
   }
   
   // Adjust for daily loss
   double dailyLossFactor = 1.0;
   if(m_dailyLoss > 0) {
      dailyLossFactor = 1.0 - (m_dailyLoss / m_maxDailyLoss * 0.5);
      dailyLossFactor = MathMax(0.5, dailyLossFactor); // Don't reduce below 50%
   }
   
   baseMultiplier *= dailyLossFactor;
   
   // Apply the adjusted multiplier
   m_currentRiskMultiplier = baseMultiplier;
}
