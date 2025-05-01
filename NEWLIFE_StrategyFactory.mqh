//+------------------------------------------------------------------+
//|                    NEWLIFE_StrategyFactory.mqh                   |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Strategy factory to create and manage strategies                 |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include "NEWLIFE_Constants.mqh"
#include "NEWLIFE_Utilities.mqh"
#include "NEWLIFE_Strategies.mqh"
#include "NEWLIFE_Indicators.mqh"
#include "NEWLIFE_RiskManagement.mqh"

//+------------------------------------------------------------------+
//| Strategy Factory Class                                           |
//+------------------------------------------------------------------+
class CStrategyFactory {
private:
   CLogger* m_logger;
   CIndicatorManager* m_indicators;
   CRiskManager* m_riskManager;
   
public:
   // Constructor
   CStrategyFactory(CIndicatorManager* indicators, CRiskManager* riskManager, CLogger* logger = NULL)
      : m_indicators(indicators), m_riskManager(riskManager), m_logger(logger) {}
   
   // Create strategy by name
   IStrategy* CreateStrategy(string strategyName) {
      // Create strategy based on name
      IStrategy* strategy = NULL;
      
      if(strategyName == "XAUUSD_Breakout") {
         CXAUUSDBreakoutStrategy* breakoutStrategy = new CXAUUSDBreakoutStrategy(LIQUIDITY_MEDIUM);
         if(breakoutStrategy != NULL) {
            breakoutStrategy.Initialize(m_indicators, m_riskManager, m_logger);
            strategy = breakoutStrategy;
         }
      }
      else if(strategyName == "XAUUSD_Range") {
         CXAUUSDRangeStrategy* rangeStrategy = new CXAUUSDRangeStrategy(LIQUIDITY_MEDIUM);
         if(rangeStrategy != NULL) {
            rangeStrategy.Initialize(m_indicators, m_riskManager, m_logger);
            strategy = rangeStrategy;
         }
      }
      else if(strategyName == "XAUUSD_Momentum") {
         CXAUUSDMomentumStrategy* momentumStrategy = new CXAUUSDMomentumStrategy(LIQUIDITY_MEDIUM);
         if(momentumStrategy != NULL) {
            momentumStrategy.Initialize(m_indicators, m_riskManager, m_logger);
            strategy = momentumStrategy;
         }
      }
      else {
         if(m_logger) {
            string logMsg = "Unknown strategy name: " + strategyName;
            m_logger.Error(logMsg);
         }
         return NULL;
      }
      
      // Log successful creation
      if(strategy != NULL && m_logger) {
         string logMsg = "Created and initialized strategy: " + strategy.GetName();
         m_logger.Info(logMsg);
      }
      
      return strategy;
   }
   
   // Create strategy for specific market conditions
   IStrategy* CreateStrategyForMarketConditions(ENUM_TREND_MODE trendMode, ENUM_LIQUIDITY_STATE liquidityState) {
      IStrategy* strategy = NULL;
      
      // Select strategy based on market conditions
      if(trendMode == TREND_MODE_BULLISH || trendMode == TREND_MODE_BEARISH) {
         // Trending market - use momentum or breakout strategy
         if(liquidityState == LIQUIDITY_HIGH) {
            // High liquidity - momentum works well
            strategy = CreateStrategy("XAUUSD_Momentum");
         }
         else {
            // Medium/low liquidity - breakout works better
            strategy = CreateStrategy("XAUUSD_Breakout");
         }
      }
      else {
         // Ranging market - use range strategy
         strategy = CreateStrategy("XAUUSD_Range");
      }
      
      return strategy;
   }
   
   // Switch strategy based on performance
   IStrategy* SwitchStrategy(IStrategy* currentStrategy, double profitFactor, double winRate) {
      // If current strategy is performing well, keep it
      if(profitFactor >= 1.5 && winRate >= 50.0) {
         return currentStrategy;
      }
      
      // Get current strategy type
      string currentName = currentStrategy.GetName();
      string newStrategyName = "";
      
      // Rotate strategies
      if(currentName.Find("Breakout") >= 0) {
         newStrategyName = "XAUUSD_Range";
      }
      else if(currentName.Find("Range") >= 0) {
         newStrategyName = "XAUUSD_Momentum";
      }
      else {
         newStrategyName = "XAUUSD_Breakout";
      }
      
      // Create new strategy
      IStrategy* newStrategy = CreateStrategy(newStrategyName);
      
      // Log the switch
      if(m_logger) {
         string logMsg = "Switching strategy: " + currentName + " -> " + newStrategyName + 
                       " (PF=" + DoubleToString(profitFactor, 2) + 
                       ", WR=" + DoubleToString(winRate, 1) + "%)";
         m_logger.Info(logMsg);
      }
      
      // Delete old strategy
      delete currentStrategy;
      
      return newStrategy;
   }
};
