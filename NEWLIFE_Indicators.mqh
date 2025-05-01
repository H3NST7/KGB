//+------------------------------------------------------------------+
//|                    NEWLIFE_Indicators.mqh                        |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Technical indicators management                                  |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include "NEWLIFE_Constants.mqh"

//+------------------------------------------------------------------+
//| Indicator Manager Class                                          |
//+------------------------------------------------------------------+
class CIndicatorManager {
private:
   // Symbol and timeframe
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframe;
   
   // Indicator handles
   int m_atrHandle;
   int m_rsiHandle;
   int m_adxHandle;
   int m_bbHandle;
   int m_momentumHandle;
   int m_maTrendHandle;
   int m_maScalpHandle;
   
   // Parameters
   int m_atrPeriod;
   int m_rsiPeriod;
   int m_adxPeriod;
   int m_maTrendPeriod;
   int m_maScalpPeriod;
   ENUM_MA_METHOD m_maMethod;
   
   // Current indicator values
   double m_atr;
   double m_adaptiveATR;
   double m_rsi;
   double m_adx;
   double m_diPlus;
   double m_diMinus;
   double m_bbUpper;
   double m_bbMiddle;
   double m_bbLower;
   double m_momentum;
   double m_maTrend;
   double m_maScalp;
   
   // Helper methods
   bool CreateATR();
   bool CreateRSI();
   bool CreateADX();
   bool CreateBB();
   bool CreateMomentum();
   bool CreateMAs();
   
public:
   // Constructor
   CIndicatorManager(string symbol, ENUM_TIMEFRAMES timeframe);
   
   // Destructor
   ~CIndicatorManager();
   
   // Initialization
   bool Initialize();
   bool CreateIndicators(int atrPeriod, int rsiPeriod, int adxPeriod, 
                        int maTrendPeriod, int maScalpPeriod, ENUM_MA_METHOD maMethod);
   
   // Update indicator values
   bool UpdateIndicators();
   
   // Getters for indicator values
   double GetATR() const { return m_atr; }
   double GetAdaptiveATR() const { return m_adaptiveATR; }
   double GetRSI() const { return m_rsi; }
   double GetADX() const { return m_adx; }
   double GetDIPlus() const { return m_diPlus; }
   double GetDIMinus() const { return m_diMinus; }
   double GetBBUpper() const { return m_bbUpper; }
   double GetBBMiddle() const { return m_bbMiddle; }
   double GetBBLower() const { return m_bbLower; }
   double GetMomentum() const { return m_momentum; }
   double GetMATrend() const { return m_maTrend; }
   double GetMAScalp() const { return m_maScalp; }
   
   // Analysis methods
   int DetectTrend() const;
   int DetermineMarketRegime() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIndicatorManager::CIndicatorManager(string symbol, ENUM_TIMEFRAMES timeframe) {
   m_symbol = symbol;
   m_timeframe = timeframe;
   
   // Initialize handles to invalid values
   m_atrHandle = INVALID_HANDLE;
   m_rsiHandle = INVALID_HANDLE;
   m_adxHandle = INVALID_HANDLE;
   m_bbHandle = INVALID_HANDLE;
   m_momentumHandle = INVALID_HANDLE;
   m_maTrendHandle = INVALID_HANDLE;
   m_maScalpHandle = INVALID_HANDLE;
   
   // Initialize indicator values
   m_atr = 0.0;
   m_adaptiveATR = 0.0;
   m_rsi = 50.0;
   m_adx = 0.0;
   m_diPlus = 0.0;
   m_diMinus = 0.0;
   m_bbUpper = 0.0;
   m_bbMiddle = 0.0;
   m_bbLower = 0.0;
   m_momentum = 100.0;
   m_maTrend = 0.0;
   m_maScalp = 0.0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CIndicatorManager::~CIndicatorManager() {
   // Release indicator handles
   if(m_atrHandle != INVALID_HANDLE) IndicatorRelease(m_atrHandle);
   if(m_rsiHandle != INVALID_HANDLE) IndicatorRelease(m_rsiHandle);
   if(m_adxHandle != INVALID_HANDLE) IndicatorRelease(m_adxHandle);
   if(m_bbHandle != INVALID_HANDLE) IndicatorRelease(m_bbHandle);
   if(m_momentumHandle != INVALID_HANDLE) IndicatorRelease(m_momentumHandle);
   if(m_maTrendHandle != INVALID_HANDLE) IndicatorRelease(m_maTrendHandle);
   if(m_maScalpHandle != INVALID_HANDLE) IndicatorRelease(m_maScalpHandle);
}

//+------------------------------------------------------------------+
//| Initialize indicator manager                                     |
//+------------------------------------------------------------------+
bool CIndicatorManager::Initialize() {
   // Make sure the symbol is available
   if(!SymbolSelect(m_symbol, true)) {
      Print("Failed to select symbol: ", m_symbol, ", error: ", GetLastError());
      return false;
   }
   
   // Check if enough history is available
   int bars = Bars(m_symbol, m_timeframe);
   if(bars < 100) {
      Print("Not enough historical data for: ", m_symbol, " on ", EnumToString(m_timeframe), 
            ", bars available: ", bars);
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create all indicator handles                                     |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateIndicators(int atrPeriod, int rsiPeriod, int adxPeriod, 
                                      int maTrendPeriod, int maScalpPeriod, 
                                      ENUM_MA_METHOD maMethod) {
   // Store parameters
   m_atrPeriod = atrPeriod;
   m_rsiPeriod = rsiPeriod;
   m_adxPeriod = adxPeriod;
   m_maTrendPeriod = maTrendPeriod;
   m_maScalpPeriod = maScalpPeriod;
   m_maMethod = maMethod;
   
   // Create all indicators
   bool success = true;
   
   success &= CreateATR();
   success &= CreateRSI();
   success &= CreateADX();
   success &= CreateBB();
   success &= CreateMomentum();
   success &= CreateMAs();
   
   // Add a delay to allow indicators to calculate
   Sleep(100);
   
   // Check handle validity before updating
   if(!success) {
      Print("One or more indicators failed to initialize");
      return false;
   }
   
   // Give time for indicators to calculate for the first time
   for(int retry = 0; retry < 3; retry++) {
      // Try to update the indicators
      if(UpdateIndicators()) {
         return true;
      }
      
      // Wait and try again
      Print("Waiting for indicator data, attempt ", retry + 1, " of 3");
      Sleep(500);
   }
   
   // Failed to update indicators after retries
   Print("Failed to get indicator data after retries");
   return false;
}

//+------------------------------------------------------------------+
//| Create ATR indicator                                             |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateATR() {
   // Release existing handle if any
   if(m_atrHandle != INVALID_HANDLE) {
      IndicatorRelease(m_atrHandle);
   }
   
   // Create ATR
   m_atrHandle = iATR(m_symbol, m_timeframe, m_atrPeriod);
   
   if(m_atrHandle == INVALID_HANDLE) {
      Print("Failed to create ATR indicator, error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create RSI indicator                                             |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateRSI() {
   // Release existing handle if any
   if(m_rsiHandle != INVALID_HANDLE) {
      IndicatorRelease(m_rsiHandle);
   }
   
   // Create RSI
   m_rsiHandle = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE);
   
   if(m_rsiHandle == INVALID_HANDLE) {
      Print("Failed to create RSI indicator, error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create ADX indicator                                             |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateADX() {
   // Release existing handle if any
   if(m_adxHandle != INVALID_HANDLE) {
      IndicatorRelease(m_adxHandle);
   }
   
   // Create ADX
   m_adxHandle = iADX(m_symbol, m_timeframe, m_adxPeriod);
   
   if(m_adxHandle == INVALID_HANDLE) {
      Print("Failed to create ADX indicator, error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create Bollinger Bands indicator                                 |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateBB() {
   // Release existing handle if any
   if(m_bbHandle != INVALID_HANDLE) {
      IndicatorRelease(m_bbHandle);
   }
   
   // Create Bollinger Bands
   m_bbHandle = iBands(m_symbol, m_timeframe, 20, 2, 0, PRICE_CLOSE);
   
   if(m_bbHandle == INVALID_HANDLE) {
      Print("Failed to create Bollinger Bands indicator, error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create Momentum indicator                                        |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateMomentum() {
   // Release existing handle if any
   if(m_momentumHandle != INVALID_HANDLE) {
      IndicatorRelease(m_momentumHandle);
   }
   
   // Create Momentum
   m_momentumHandle = iMomentum(m_symbol, m_timeframe, 14, PRICE_CLOSE);
   
   if(m_momentumHandle == INVALID_HANDLE) {
      Print("Failed to create Momentum indicator, error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Create Moving Average indicators                                 |
//+------------------------------------------------------------------+
bool CIndicatorManager::CreateMAs() {
   // Release existing handles if any
   if(m_maTrendHandle != INVALID_HANDLE) {
      IndicatorRelease(m_maTrendHandle);
   }
   
   if(m_maScalpHandle != INVALID_HANDLE) {
      IndicatorRelease(m_maScalpHandle);
   }
   
   // Create Moving Averages
   m_maTrendHandle = iMA(m_symbol, m_timeframe, m_maTrendPeriod, 0, m_maMethod, PRICE_CLOSE);
   
   if(m_maTrendHandle == INVALID_HANDLE) {
      Print("Failed to create Trend MA indicator, error: ", GetLastError());
      return false;
   }
   
   m_maScalpHandle = iMA(m_symbol, m_timeframe, m_maScalpPeriod, 0, m_maMethod, PRICE_CLOSE);
   
   if(m_maScalpHandle == INVALID_HANDLE) {
      Print("Failed to create Scalp MA indicator, error: ", GetLastError());
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Update all indicator values                                      |
//+------------------------------------------------------------------+
bool CIndicatorManager::UpdateIndicators() {
   // Check all handles
   if(m_atrHandle == INVALID_HANDLE || m_rsiHandle == INVALID_HANDLE || 
      m_adxHandle == INVALID_HANDLE || m_bbHandle == INVALID_HANDLE || 
      m_momentumHandle == INVALID_HANDLE || m_maTrendHandle == INVALID_HANDLE || 
      m_maScalpHandle == INVALID_HANDLE) {
      Print("One or more indicator handles are invalid");
      return false;
   }
   
   // Array for copying indicator data
   double buffer[];
   
   // Update ATR
   ArraySetAsSeries(buffer, true);
   int atrCopied = CopyBuffer(m_atrHandle, 0, 0, 3, buffer);
   if(atrCopied < 3) {
      int error = GetLastError();
      Print("Failed to copy ATR data, error: ", error);
      
      // For debugging
      Print("ATR handle: ", m_atrHandle, ", Symbol: ", m_symbol, ", Timeframe: ", 
            EnumToString(m_timeframe), ", Period: ", m_atrPeriod);
      
      return false;
   }
   m_atr = buffer[0];
   
   // Calculate adaptive ATR (weighted average of recent ATR values)
   m_adaptiveATR = (buffer[0] * 3 + buffer[1] * 2 + buffer[2]) / 6.0;
   
   // Update RSI
   int rsiCopied = CopyBuffer(m_rsiHandle, 0, 0, 1, buffer);
   if(rsiCopied < 1) {
      Print("Failed to copy RSI data, error: ", GetLastError());
      return false;
   }
   m_rsi = buffer[0];
   
   // Update ADX and DI
   int adxCopied = CopyBuffer(m_adxHandle, 0, 0, 1, buffer);
   if(adxCopied < 1) {
      Print("Failed to copy ADX data, error: ", GetLastError());
      return false;
   }
   m_adx = buffer[0];
   
   int diPlusCopied = CopyBuffer(m_adxHandle, 1, 0, 1, buffer);
   if(diPlusCopied < 1) {
      Print("Failed to copy DI+ data, error: ", GetLastError());
      return false;
   }
   m_diPlus = buffer[0];
   
   int diMinusCopied = CopyBuffer(m_adxHandle, 2, 0, 1, buffer);
   if(diMinusCopied < 1) {
      Print("Failed to copy DI- data, error: ", GetLastError());
      return false;
   }
   m_diMinus = buffer[0];
   
   // Update Bollinger Bands
   int bbMiddleCopied = CopyBuffer(m_bbHandle, 0, 0, 1, buffer);
   if(bbMiddleCopied < 1) {
      Print("Failed to copy BB middle data, error: ", GetLastError());
      return false;
   }
   m_bbMiddle = buffer[0];
   
   int bbUpperCopied = CopyBuffer(m_bbHandle, 1, 0, 1, buffer);
   if(bbUpperCopied < 1) {
      Print("Failed to copy BB upper data, error: ", GetLastError());
      return false;
   }
   m_bbUpper = buffer[0];
   
   int bbLowerCopied = CopyBuffer(m_bbHandle, 2, 0, 1, buffer);
   if(bbLowerCopied < 1) {
      Print("Failed to copy BB lower data, error: ", GetLastError());
      return false;
   }
   m_bbLower = buffer[0];
   
   // Update Momentum
   int momentumCopied = CopyBuffer(m_momentumHandle, 0, 0, 1, buffer);
   if(momentumCopied < 1) {
      Print("Failed to copy Momentum data, error: ", GetLastError());
      return false;
   }
   m_momentum = buffer[0];
   
   // Update Moving Averages
   int maTrendCopied = CopyBuffer(m_maTrendHandle, 0, 0, 1, buffer);
   if(maTrendCopied < 1) {
      Print("Failed to copy Trend MA data, error: ", GetLastError());
      return false;
   }
   m_maTrend = buffer[0];
   
   int maScalpCopied = CopyBuffer(m_maScalpHandle, 0, 0, 1, buffer);
   if(maScalpCopied < 1) {
      Print("Failed to copy Scalp MA data, error: ", GetLastError());
      return false;
   }
   m_maScalp = buffer[0];
   
   return true;
}

//+------------------------------------------------------------------+
//| Detect current market trend                                      |
//+------------------------------------------------------------------+
int CIndicatorManager::DetectTrend() const {
   // Simplified stub implementation
   return 0; // TREND_NONE
}

//+------------------------------------------------------------------+
//| Determine overall market regime                                  |
//+------------------------------------------------------------------+
int CIndicatorManager::DetermineMarketRegime() const {
   // Simplified stub implementation
   return 3; // REGIME_CONSOLIDATION
}
