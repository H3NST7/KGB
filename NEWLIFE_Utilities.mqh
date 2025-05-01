//+------------------------------------------------------------------+
//|                    NEWLIFE_Utilities.mqh                         |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Utility functions and helper classes                             |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

// Logging levels
enum ENUM_LOG_LEVEL {
   LOG_LEVEL_ERROR,    // Only log errors
   LOG_LEVEL_WARN,     // Log warnings and errors
   LOG_LEVEL_INFO,     // Log info, warnings, and errors
   LOG_LEVEL_DEBUG,    // Log everything
   LOG_LEVEL_TRACE     // Detailed trace logs
};

//+------------------------------------------------------------------+
//| Logger Class                                                     |
//+------------------------------------------------------------------+
class CLogger {
private:
   string m_prefix;
   ENUM_LOG_LEVEL m_level;
   bool m_logToFile;
   int m_fileHandle;
   
   string GetTimeStr() const {
      return TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   }
   
   void WriteToFile(const string &message) {
      if(m_fileHandle != INVALID_HANDLE) {
         FileWriteString(m_fileHandle, message + "\n");
         FileFlush(m_fileHandle);
      }
   }
   
public:
   // Constructor
   CLogger(string prefix = "", ENUM_LOG_LEVEL level = LOG_LEVEL_INFO, bool logToFile = false)
      : m_prefix(prefix), m_level(level), m_logToFile(logToFile), m_fileHandle(INVALID_HANDLE) {
      
      if(m_logToFile) {
         string filename = "NEWLIFE_" + m_prefix + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
         m_fileHandle = FileOpen(filename, FILE_WRITE|FILE_TXT);
      }
   }
   
   // Destructor
   ~CLogger() {
      if(m_fileHandle != INVALID_HANDLE) {
         FileClose(m_fileHandle);
      }
   }
   
   // Log methods
   void Error(const string &message) {
      if(m_level >= LOG_LEVEL_ERROR) {
         string logMsg = GetTimeStr() + " [ERROR] " + m_prefix + ": " + message;
         Print(logMsg);
         if(m_logToFile) WriteToFile(logMsg);
      }
   }
   
   void Warn(const string &message) {
      if(m_level >= LOG_LEVEL_WARN) {
         string logMsg = GetTimeStr() + " [WARN] " + m_prefix + ": " + message;
         Print(logMsg);
         if(m_logToFile) WriteToFile(logMsg);
      }
   }
   
   void Info(const string &message) {
      if(m_level >= LOG_LEVEL_INFO) {
         string logMsg = GetTimeStr() + " [INFO] " + m_prefix + ": " + message;
         Print(logMsg);
         if(m_logToFile) WriteToFile(logMsg);
      }
   }
   
   void Debug(const string &message) {
      if(m_level >= LOG_LEVEL_DEBUG) {
         string logMsg = GetTimeStr() + " [DEBUG] " + m_prefix + ": " + message;
         Print(logMsg);
         if(m_logToFile) WriteToFile(logMsg);
      }
   }
   
   void Trace(const string &message) {
      if(m_level >= LOG_LEVEL_TRACE) {
         string logMsg = GetTimeStr() + " [TRACE] " + m_prefix + ": " + message;
         Print(logMsg);
         if(m_logToFile) WriteToFile(logMsg);
      }
   }
   
   // Set log level
   void SetLevel(ENUM_LOG_LEVEL level) {
      m_level = level;
   }
};

//+------------------------------------------------------------------+
//| Utility functions                                                |
//+------------------------------------------------------------------+
// Calculate distance in points between two prices
double CalculateDistanceInPoints(double price1, double price2, string symbol = NULL) {
   if(symbol == NULL) symbol = Symbol();
   
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point == 0) return 0;
   
   return MathAbs(price1 - price2) / point;
}

// Normalize price to tick size
double NormalizePrice(double price, string symbol = NULL) {
   if(symbol == NULL) symbol = Symbol();
   
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0) return price;
   
   return MathRound(price / tickSize) * tickSize;
}

// Get current spread in points
double GetCurrentSpreadPoints(string symbol = NULL) {
   if(symbol == NULL) symbol = Symbol();
   
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(point == 0) return 0;
   
   return (ask - bid) / point;
}
