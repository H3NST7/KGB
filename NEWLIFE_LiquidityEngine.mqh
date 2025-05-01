//+------------------------------------------------------------------+
//|                  NEWLIFE_LiquidityEngine.mqh                     |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Liquidity analysis and management system                         |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include "NEWLIFE_Constants.mqh"
#include "NEWLIFE_Utilities.mqh"

//+------------------------------------------------------------------+
//| Liquidity Analyzer Class                                         |
//+------------------------------------------------------------------+
class CLiquidityAnalyzer {
private:
   string m_symbol;                   // Symbol to analyze
   ENUM_LIQUIDITY_STATE m_currentState; // Current liquidity state
   
   // Liquidity metrics
   double m_spreadHistory[20];        // Spread history
   double m_volumeHistory[20];        // Volume history
   int m_historyIndex;                // Current index in history arrays
   
   // Thresholds
   double m_highLiquiditySpreadThreshold;
   double m_lowLiquiditySpreadThreshold;
   double m_highLiquidityVolumeThreshold;
   double m_lowLiquidityVolumeThreshold;
   
   // Update frequency control
   datetime m_lastFullUpdate;
   
   // Methods for analysis
   void UpdateMetrics(const MqlTick &tick);
   ENUM_LIQUIDITY_STATE AnalyzeLiquidity();
   double CalculateAverageSpread() const;
   double CalculateAverageVolume() const;
   
public:
   // Constructor
   CLiquidityAnalyzer(string symbol);
   
   // Initialize the analyzer
   bool Initialize();
   
   // Update liquidity state with new tick data
   void Update(const MqlTick &tick);
   
   // Get current liquidity state
   ENUM_LIQUIDITY_STATE GetCurrentState() const { return m_currentState; }
   
   // Get average spread
   double GetAverageSpread() const { return CalculateAverageSpread(); }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLiquidityAnalyzer::CLiquidityAnalyzer(string symbol) {
   m_symbol = symbol;
   m_currentState = LIQUIDITY_MEDIUM;
   m_historyIndex = 0;
   m_lastFullUpdate = 0;
   
   // Initialize historical arrays
   ArrayInitialize(m_spreadHistory, 0.0);
   ArrayInitialize(m_volumeHistory, 0.0);
   
   // Set default thresholds
   m_highLiquiditySpreadThreshold = 20.0;
   m_lowLiquiditySpreadThreshold = 40.0;
   m_highLiquidityVolumeThreshold = 0.0;  // Will be set in Initialize based on symbol avg
   m_lowLiquidityVolumeThreshold = 0.0;   // Will be set in Initialize based on symbol avg
}

//+------------------------------------------------------------------+
//| Initialize the analyzer                                          |
//+------------------------------------------------------------------+
bool CLiquidityAnalyzer::Initialize() {
   // Adjust thresholds based on symbol
   if(m_symbol == "XAUUSD") {
      m_highLiquiditySpreadThreshold = 35.0;
      m_lowLiquiditySpreadThreshold = 60.0;
   } else {
      // For other symbols, use default values
      m_highLiquiditySpreadThreshold = 20.0;
      m_lowLiquiditySpreadThreshold = 40.0;
   }
   
   // Get initial volume thresholds based on recent history
   // This would ideally look at historical data to set baseline
   m_highLiquidityVolumeThreshold = 100.0;  // Placeholder
   m_lowLiquidityVolumeThreshold = 50.0;    // Placeholder
   
   return true;
}

//+------------------------------------------------------------------+
//| Update liquidity state with new tick data                        |
//+------------------------------------------------------------------+
void CLiquidityAnalyzer::Update(const MqlTick &tick) {
   // Update metrics with new tick
   UpdateMetrics(tick);
   
   // Full liquidity analysis - do not run on every tick
   datetime currentTime = TimeCurrent();
   
   // Only update every 5 seconds to avoid excessive processing
   if(currentTime - m_lastFullUpdate >= 5) {
      m_lastFullUpdate = currentTime;
      
      // Analyze liquidity and update current state
      ENUM_LIQUIDITY_STATE newState = AnalyzeLiquidity();
      
      // Only change state if it's different
      if(newState != m_currentState) {
         m_currentState = newState;
      }
   }
}

//+------------------------------------------------------------------+
//| Update liquidity metrics with new tick                           |
//+------------------------------------------------------------------+
void CLiquidityAnalyzer::UpdateMetrics(const MqlTick &tick) {
   // Calculate current spread in points
   double pointSize = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double currentSpread = (tick.ask - tick.bid) / pointSize;
   
   // Update history arrays in a circular buffer
   m_spreadHistory[m_historyIndex] = currentSpread;
   m_volumeHistory[m_historyIndex] = (double)tick.volume; // Convert ulong to double safely
   
   // Move to next position in circular buffer
   m_historyIndex = (m_historyIndex + 1) % 20;
}

//+------------------------------------------------------------------+
//| Analyze current liquidity state                                  |
//+------------------------------------------------------------------+
ENUM_LIQUIDITY_STATE CLiquidityAnalyzer::AnalyzeLiquidity() {
   // Calculate average metrics
   double avgSpread = CalculateAverageSpread();
   double avgVolume = CalculateAverageVolume();
   
   // Determine liquidity state based on combination of factors
   if(avgSpread < m_highLiquiditySpreadThreshold && avgVolume > m_highLiquidityVolumeThreshold) {
      // Low spread and high volume indicate high liquidity
      return LIQUIDITY_HIGH;
   } else if(avgSpread > m_lowLiquiditySpreadThreshold || avgVolume < m_lowLiquidityVolumeThreshold) {
      // High spread or low volume indicate low liquidity
      return LIQUIDITY_LOW;
   } else {
      // Default to medium liquidity
      return LIQUIDITY_MEDIUM;
   }
}

//+------------------------------------------------------------------+
//| Calculate average spread from history                            |
//+------------------------------------------------------------------+
double CLiquidityAnalyzer::CalculateAverageSpread() const {
   double sum = 0.0;
   int countValues = 0;
   
   // Sum all non-zero spread values
   for(int i = 0; i < 20; i++) {
      if(m_spreadHistory[i] > 0.0) {
         sum += m_spreadHistory[i];
         countValues++;
      }
   }
   
   // Return average or zero if no data
   return (countValues > 0) ? (sum / countValues) : 0.0;
}

//+------------------------------------------------------------------+
//| Calculate average volume from history                            |
//+------------------------------------------------------------------+
double CLiquidityAnalyzer::CalculateAverageVolume() const {
   double sum = 0.0;
   int countValues = 0;
   
   // Sum all non-zero volume values
   for(int i = 0; i < 20; i++) {
      if(m_volumeHistory[i] > 0.0) {
         sum += m_volumeHistory[i];
         countValues++;
      }
   }
   
   // Return average or zero if no data
   return (countValues > 0) ? (sum / countValues) : 0.0;
}
