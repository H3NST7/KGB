//+------------------------------------------------------------------+
//|                    NEWLIFE_OrderExecution.mqh                    |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Order execution and management                                   |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include <Trade\Trade.mqh>
#include <Arrays\ArrayObj.mqh>
#include "NEWLIFE_Constants.mqh"
#include "NEWLIFE_Utilities.mqh"

// Order structure for queueing
struct OrderParams {
   ENUM_ORDER_TYPE type;
   double volume;
   double price;
   double sl;
   double tp;
   string comment;
   datetime timestamp;
};

//+------------------------------------------------------------------+
//| Order Manager Class                                              |
//+------------------------------------------------------------------+
class COrderManager {
private:
   // Core components
   CTrade m_trade;
   
   // Order queue
   OrderParams m_orderQueue[];
   int m_queueSize;
   int m_maxQueueSize;
   
   // Configuration
   int m_magicNumber;
   int m_maxRetryAttempts;
   double m_slippage;
   string m_symbol;
   CLogger* m_logger;
   
   // Internal state
   int m_lastErrorCode;
   
   // Private methods
   void QueueOrder(ENUM_ORDER_TYPE type, double volume, double price, double sl, double tp, string comment);
   void RemoveProcessedOrders(int count);
   bool IsFatalError(int errorCode);
   
public:
   // Constructor
   COrderManager(int magicNumber, int maxQueueSize = 100, int maxRetryAttempts = 5, double slippage = 3.0);
   COrderManager(int magicNumber, string symbol = NULL, CLogger* logger = NULL);
   
   // Initialize the order manager
   bool Initialize();
   
   // Order execution methods
   bool ExecuteMarketOrder(ENUM_ORDER_TYPE type, double volume, double price, double sl, double tp, string comment);
   bool ExecutePendingOrder(ENUM_ORDER_TYPE type, double volume, double price, double sl, double tp, string comment, datetime expiration = 0);
   
   // Order management
   bool ModifyOrder(ulong ticket, double price, double sl, double tp);
   bool CloseOrder(ulong ticket, double volume = 0.0);
   bool DeleteOrder(ulong ticket);
   
   // Order queue operations
   void ProcessQueue();
   void ClearQueue();
   
   // Utility methods
   int GetLastError() const { return m_lastErrorCode; }
   bool GetTicketsByMagic(ulong &tickets[]);
   
   // Simplified methods from Utilities
   bool OpenPosition(ENUM_ORDER_TYPE type, double volume, double price, double stopLoss, double takeProfit, string comment = "") {
      return ExecuteMarketOrder(type, volume, price, stopLoss, takeProfit, comment);
   }
   
   bool ClosePosition(ulong ticket) {
      return CloseOrder(ticket);
   }
   
   int CloseAllPositions() {
      ulong tickets[];
      if(!GetTicketsByMagic(tickets)) return 0;
      
      int closed = 0;
      for(int i = 0; i < ArraySize(tickets); i++) {
         if(CloseOrder(tickets[i])) closed++;
      }
      return closed;
   }
   
   bool ModifyPosition(ulong ticket, double stopLoss, double takeProfit) {
      return ModifyOrder(ticket, 0, stopLoss, takeProfit);
   }
   
   double GetPositionProfit(ulong ticket) {
      if(PositionSelectByTicket(ticket)) {
         return PositionGetDouble(POSITION_PROFIT);
      }
      return 0.0;
   }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
COrderManager::COrderManager(int magicNumber, int maxQueueSize, int maxRetryAttempts, double slippage) {
   m_magicNumber = magicNumber;
   m_maxQueueSize = maxQueueSize;
   m_maxRetryAttempts = maxRetryAttempts;
   m_slippage = slippage;
   m_queueSize = 0;
   m_lastErrorCode = 0;
   m_symbol = Symbol();
   m_logger = NULL;
   
   // Initialize trade object
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetDeviationInPoints((ulong)m_slippage); // Fixed: explicit cast to ulong
   m_trade.SetMarginMode();
}

//+------------------------------------------------------------------+
//| Alternative Constructor                                          |
//+------------------------------------------------------------------+
COrderManager::COrderManager(int magicNumber, string symbol, CLogger* logger) {
   m_magicNumber = magicNumber;
   m_symbol = (symbol == NULL) ? Symbol() : symbol;
   m_logger = logger;
   
   // Default settings
   m_maxQueueSize = 100;
   m_maxRetryAttempts = 5;
   m_slippage = 3.0;
   m_queueSize = 0;
   m_lastErrorCode = 0;
   
   // Initialize trade object
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetDeviationInPoints((ulong)m_slippage);
   m_trade.SetMarginMode();
}

//+------------------------------------------------------------------+
//| Initialize the order manager                                     |
//+------------------------------------------------------------------+
bool COrderManager::Initialize() {
   // Nothing specific to initialize beyond constructor
   return true;
}

//+------------------------------------------------------------------+
//| Execute a market order                                           |
//+------------------------------------------------------------------+
bool COrderManager::ExecuteMarketOrder(ENUM_ORDER_TYPE type, double volume, double price, 
                                    double sl, double tp, string comment) {
   // Validate inputs
   if(volume <= 0.0) {
      m_lastErrorCode = -1;
      if(m_logger) {
         string logMsg = "Invalid volume for market order: " + DoubleToString(volume);
         m_logger.Error(logMsg);
      }
      else Print("Invalid volume for market order: ", volume);
      return false;
   }
   
   // Prepare order with retry logic
   bool result = false;
   int attempts = 0;
   
   while(!result && attempts < m_maxRetryAttempts) {
      attempts++;
      
      // Execute order based on type
      if(type == ORDER_TYPE_BUY) {
         result = m_trade.Buy(volume, NULL, 0, sl, tp, comment);
      } else if(type == ORDER_TYPE_SELL) {
         result = m_trade.Sell(volume, NULL, 0, sl, tp, comment);
      } else {
         m_lastErrorCode = -2;
         if(m_logger) {
            string logMsg = "Invalid order type for market order: " + EnumToString(type);
            m_logger.Error(logMsg);
         }
         else Print("Invalid order type for market order: ", EnumToString(type));
         return false;
      }
      
      // Check result
      if(result) {
         return true;
      } else {
         // Store error and retry if needed
         m_lastErrorCode = (int)m_trade.ResultRetcode();
         if(m_logger) {
            string logMsg = "Market order attempt " + IntegerToString(attempts) + 
                           " failed with error " + IntegerToString(m_lastErrorCode) + 
                           ": " + m_trade.ResultRetcodeDescription();
            m_logger.Warn(logMsg);
         }
         else Print("Market order attempt ", attempts, " failed with error ", m_lastErrorCode, 
                    ": ", m_trade.ResultRetcodeDescription());
               
         // If fatal error, stop retrying
         if(IsFatalError(m_lastErrorCode)) {
            break;
         }
         
         // Wait before retry
         Sleep(500);
      }
   }
   
   // If we reached here, all attempts failed
   if(!result) {
      // Queue the order for later processing
      QueueOrder(type, volume, price, sl, tp, comment);
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Execute a pending order                                          |
//+------------------------------------------------------------------+
bool COrderManager::ExecutePendingOrder(ENUM_ORDER_TYPE type, double volume, double price, 
                                      double sl, double tp, string comment, datetime expiration) {
   // Validate inputs
   if(volume <= 0.0 || price <= 0.0) {
      m_lastErrorCode = -1;
      if(m_logger) {
         string logMsg = "Invalid parameters for pending order: Volume=" + 
                       DoubleToString(volume) + ", Price=" + DoubleToString(price);
         m_logger.Error(logMsg);
      }
      else Print("Invalid parameters for pending order: Volume=", volume, ", Price=", price);
      return false;
   }
   
   // Prepare order with retry logic
   bool result = false;
   int attempts = 0;
   
   while(!result && attempts < m_maxRetryAttempts) {
      attempts++;
      
      // Execute pending order based on type
      switch(type) {
         case ORDER_TYPE_BUY_LIMIT:
            result = m_trade.BuyLimit(volume, price, NULL, sl, tp, ORDER_TIME_GTC, expiration, comment);
            break;
            
         case ORDER_TYPE_SELL_LIMIT:
            result = m_trade.SellLimit(volume, price, NULL, sl, tp, ORDER_TIME_GTC, expiration, comment);
            break;
            
         case ORDER_TYPE_BUY_STOP:
            result = m_trade.BuyStop(volume, price, NULL, sl, tp, ORDER_TIME_GTC, expiration, comment);
            break;
            
         case ORDER_TYPE_SELL_STOP:
            result = m_trade.SellStop(volume, price, NULL, sl, tp, ORDER_TIME_GTC, expiration, comment);
            break;
            
         default:
            m_lastErrorCode = -2;
            if(m_logger) {
               string logMsg = "Invalid order type for pending order: " + EnumToString(type);
               m_logger.Error(logMsg);
            }
            else Print("Invalid order type for pending order: ", EnumToString(type));
            return false;
      }
      
      // Check result
      if(result) {
         return true;
      } else {
         // Store error and retry if needed
         m_lastErrorCode = (int)m_trade.ResultRetcode();
         if(m_logger) {
            string logMsg = "Pending order attempt " + IntegerToString(attempts) + 
                           " failed with error " + IntegerToString(m_lastErrorCode) + 
                           ": " + m_trade.ResultRetcodeDescription();
            m_logger.Warn(logMsg);
         }
         else Print("Pending order attempt ", attempts, " failed with error ", m_lastErrorCode, 
                    ": ", m_trade.ResultRetcodeDescription());
               
         // If fatal error, stop retrying
         if(IsFatalError(m_lastErrorCode)) {
            break;
         }
         
         // Wait before retry
         Sleep(500);
      }
   }
   
   // If we reached here, all attempts failed
   if(!result) {
      // Queue the order for later processing
      QueueOrder(type, volume, price, sl, tp, comment);
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Modify an existing order                                         |
//+------------------------------------------------------------------+
bool COrderManager::ModifyOrder(ulong ticket, double price, double sl, double tp) {
   // Validate inputs
   if(ticket <= 0) {
      m_lastErrorCode = -1;
      if(m_logger) {
         string logMsg = "Invalid ticket for order modification: " + IntegerToString(ticket);
         m_logger.Error(logMsg);
      }
      else Print("Invalid ticket for order modification: ", ticket);
      return false;
   }
   
   // Prepare modify with retry logic
   bool result = false;
   int attempts = 0;
   
   while(!result && attempts < m_maxRetryAttempts) {
      attempts++;
      
      // Try to modify the order
      result = m_trade.OrderModify(ticket, price, sl, tp, ORDER_TIME_GTC, 0);
      
      // Check result
      if(result) {
         return true;
      } else {
         // Store error and retry if needed
         m_lastErrorCode = (int)m_trade.ResultRetcode();
         if(m_logger) {
            string logMsg = "Order modify attempt " + IntegerToString(attempts) + 
                           " failed with error " + IntegerToString(m_lastErrorCode) + 
                           ": " + m_trade.ResultRetcodeDescription();
            m_logger.Warn(logMsg);
         }
         else Print("Order modify attempt ", attempts, " failed with error ", m_lastErrorCode, 
                    ": ", m_trade.ResultRetcodeDescription());
               
         // If fatal error, stop retrying
         if(IsFatalError(m_lastErrorCode)) {
            break;
         }
         
         // Wait before retry
         Sleep(500);
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Close a position                                                 |
//+------------------------------------------------------------------+
bool COrderManager::CloseOrder(ulong ticket, double volume) {
   // Validate inputs
   if(ticket <= 0) {
      m_lastErrorCode = -1;
      if(m_logger) {
         string logMsg = "Invalid ticket for position close: " + IntegerToString(ticket);
         m_logger.Error(logMsg);
      }
      else Print("Invalid ticket for position close: ", ticket);
      return false;
   }
   
   // Prepare close with retry logic
   bool result = false;
   int attempts = 0;
   
   while(!result && attempts < m_maxRetryAttempts) {
      attempts++;
      
      // Try to close the position
      if(volume <= 0.0) {
         // Close entire position
         result = m_trade.PositionClose(ticket);
      } else {
         // Partial close
         result = m_trade.PositionClosePartial(ticket, volume);
      }
      
      // Check result
      if(result) {
         return true;
      } else {
         // Store error and retry if needed
         m_lastErrorCode = (int)m_trade.ResultRetcode();
         if(m_logger) {
            string logMsg = "Position close attempt " + IntegerToString(attempts) + 
                           " failed with error " + IntegerToString(m_lastErrorCode) + 
                           ": " + m_trade.ResultRetcodeDescription();
            m_logger.Warn(logMsg);
         }
         else Print("Position close attempt ", attempts, " failed with error ", m_lastErrorCode, 
                    ": ", m_trade.ResultRetcodeDescription());
               
         // If fatal error, stop retrying
         if(IsFatalError(m_lastErrorCode)) {
            break;
         }
         
         // Wait before retry
         Sleep(500);
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Delete a pending order                                           |
//+------------------------------------------------------------------+
bool COrderManager::DeleteOrder(ulong ticket) {
   // Validate inputs
   if(ticket <= 0) {
      m_lastErrorCode = -1;
      if(m_logger) {
         string logMsg = "Invalid ticket for order deletion: " + IntegerToString(ticket);
         m_logger.Error(logMsg);
      }
      else Print("Invalid ticket for order deletion: ", ticket);
      return false;
   }
   
   // Prepare delete with retry logic
   bool result = false;
   int attempts = 0;
   
   while(!result && attempts < m_maxRetryAttempts) {
      attempts++;
      
      // Try to delete the order
      result = m_trade.OrderDelete(ticket);
      
      // Check result
      if(result) {
         return true;
      } else {
         // Store error and retry if needed
         m_lastErrorCode = (int)m_trade.ResultRetcode();
         if(m_logger) {
            string logMsg = "Order delete attempt " + IntegerToString(attempts) + 
                           " failed with error " + IntegerToString(m_lastErrorCode) + 
                           ": " + m_trade.ResultRetcodeDescription();
            m_logger.Warn(logMsg);
         }
         else Print("Order delete attempt ", attempts, " failed with error ", m_lastErrorCode, 
                    ": ", m_trade.ResultRetcodeDescription());
               
         // If fatal error, stop retrying
         if(IsFatalError(m_lastErrorCode)) {
            break;
         }
         
         // Wait before retry
         Sleep(500);
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Process queued orders                                            |
//+------------------------------------------------------------------+
void COrderManager::ProcessQueue() {
   // Check if queue is empty
   if(m_queueSize <= 0) {
      return;
   }
   
   // Process each order in the queue
   int processedCount = 0;
   
   for(int i = 0; i < m_queueSize; i++) {
      OrderParams order = m_orderQueue[i];
      
      // Check if order has expired (older than 5 minutes)
      if(TimeCurrent() - order.timestamp > 300) {
         // Skip expired orders
         processedCount++;
         continue;
      }
      
      // Try to execute the order based on type
      bool result = false;
      
      if(order.type == ORDER_TYPE_BUY || order.type == ORDER_TYPE_SELL) {
         // Market order
         result = ExecuteMarketOrder(
            order.type, 
            order.volume, 
            order.price, 
            order.sl, 
            order.tp, 
            order.comment
         );
      } else {
         // Pending order
         result = ExecutePendingOrder(
            order.type, 
            order.volume, 
            order.price, 
            order.sl, 
            order.tp, 
            order.comment,
            0  // No expiration
         );
      }
      
      // If order was executed successfully, mark as processed
      if(result) {
         processedCount++;
      }
   }
   
   // Clean up processed orders from queue
   if(processedCount > 0) {
      RemoveProcessedOrders(processedCount);
   }
}

//+------------------------------------------------------------------+
//| Clear all orders from the queue                                  |
//+------------------------------------------------------------------+
void COrderManager::ClearQueue() {
   ArrayFree(m_orderQueue);
   m_queueSize = 0;
}

//+------------------------------------------------------------------+
//| Queue an order for later processing                              |
//+------------------------------------------------------------------+
void COrderManager::QueueOrder(ENUM_ORDER_TYPE type, double volume, double price, 
                             double sl, double tp, string comment) {
   // Check if queue is full
   if(m_queueSize >= m_maxQueueSize) {
      if(m_logger) {
         string logMsg = "Order queue is full, cannot add more orders";
         m_logger.Warn(logMsg);
      }
      else Print("Order queue is full, cannot add more orders");
      return;
   }
   
   // Add order to queue
   m_queueSize++;
   ArrayResize(m_orderQueue, m_queueSize);
   
   // Fill order parameters
   m_orderQueue[m_queueSize - 1].type = type;
   m_orderQueue[m_queueSize - 1].volume = volume;
   m_orderQueue[m_queueSize - 1].price = price;
   m_orderQueue[m_queueSize - 1].sl = sl;
   m_orderQueue[m_queueSize - 1].tp = tp;
   m_orderQueue[m_queueSize - 1].comment = comment;
   m_orderQueue[m_queueSize - 1].timestamp = TimeCurrent();
   
   if(m_logger) {
      string logMsg = "Order queued for later execution: " + EnumToString(type) + ", Volume: " + DoubleToString(volume);
      m_logger.Info(logMsg);
   }
   else Print("Order queued for later execution: ", EnumToString(type), ", Volume: ", volume);
}

//+------------------------------------------------------------------+
//| Remove processed orders from the queue                           |
//+------------------------------------------------------------------+
void COrderManager::RemoveProcessedOrders(int count) {
   // Check if count is valid
   if(count <= 0 || count > m_queueSize) {
      return;
   }
   
   // Remove the first 'count' orders
   for(int i = 0; i < m_queueSize - count; i++) {
      m_orderQueue[i] = m_orderQueue[i + count];
   }
   
   // Resize the array
   m_queueSize -= count;
   ArrayResize(m_orderQueue, m_queueSize);
}

//+------------------------------------------------------------------+
//| Check if an error code represents a fatal error                  |
//+------------------------------------------------------------------+
bool COrderManager::IsFatalError(int errorCode) {
   // List of fatal errors that should stop retrying
   switch(errorCode) {
      // Account errors
      case 134: // ERR_NOT_ENOUGH_MONEY
      case 64:  // ERR_ACCOUNT_DISABLED
      case 65:  // ERR_INVALID_ACCOUNT
      
      // Trade context errors
      case 146: // ERR_TRADE_CONTEXT_BUSY
      case 148: // ERR_TRADE_TOO_MANY_ORDERS
      
      // Symbol errors
      case 129: // ERR_INVALID_PRICE
      case 130: // ERR_INVALID_STOPS
      case 132: // ERR_MARKET_CLOSED
      case 133: // ERR_TRADE_DISABLED
         return true;
         
      default:
         return false;
   }
}

//+------------------------------------------------------------------+
//| Get all tickets with this EA's magic number                      |
//+------------------------------------------------------------------+
bool COrderManager::GetTicketsByMagic(ulong &tickets[]) {
   // Clear the array
   ArrayFree(tickets);
   
   // Count matching positions
   int countTickets = 0;
   
   // Check positions
   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0 && PositionSelectByTicket(ticket)) {
         long magic = PositionGetInteger(POSITION_MAGIC);
         
         if(magic == m_magicNumber) {
            countTickets++;
            ArrayResize(tickets, countTickets);
            tickets[countTickets - 1] = ticket;
         }
      }
   }
   
   // Check pending orders
   for(int i = 0; i < OrdersTotal(); i++) {
      ulong ticket = OrderGetTicket(i);
      
      if(ticket > 0 && OrderSelect(ticket)) {
         long magic = OrderGetInteger(ORDER_MAGIC);
         
         if(magic == m_magicNumber) {
            countTickets++;
            ArrayResize(tickets, countTickets);
            tickets[countTickets - 1] = ticket;
         }
      }
   }
   
   return (countTickets > 0);
}
