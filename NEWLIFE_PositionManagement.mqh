//+------------------------------------------------------------------+
//|                    NEWLIFE_PositionManagement.mqh                |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Position management for active trades                            |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include "NEWLIFE_Constants.mqh"
#include "NEWLIFE_Indicators.mqh"

//+------------------------------------------------------------------+
//| Position Manager Class                                           |
//+------------------------------------------------------------------+
class CPositionManager {
private:
   // Core components
   CTrade m_trade;
   CPositionInfo m_positionInfo;
   
   // Configuration
   int m_magicNumber;
   bool m_trailingEnabled;
   double m_trailingTrigger;
   double m_trailingStep;
   bool m_partialCloseEnabled;
   double m_partialClosePercent;
   
   // Trailing state
   struct TrailingState {
      ulong ticket;
      double activationPrice;
      double lastTrailPrice;
      bool trailingActive;
   };
   
   TrailingState m_trailingStates[];
   
   // Position tracking
   bool m_positionsTracked;
   
   // Private helper methods
   void InitializeTrailingStates();
   void ManageSinglePosition(ulong ticket, const MqlTick &tick, CIndicatorManager *indMgr);
   bool IsOurPosition(ulong ticket);
   double NormalizePrice(string symbolName, double price);
   
public:
   // Constructor
   CPositionManager(int magicNumber, bool trailingEnabled = true, 
                   double trailingTrigger = 300.0, double trailingStep = 100.0,
                   bool partialCloseEnabled = true, double partialClosePercent = 50.0);
   
   // Initialize the position manager
   bool Initialize();
   
   // Manage all open positions
   void ManagePositions(const MqlTick &tick, CIndicatorManager *indMgr = NULL);
   
   // Close all positions
   bool CloseAllPositions(string reason);
   
   // Position modification methods
   bool ModifyPosition(ulong ticket, double sl, double tp);
   bool ClosePosition(ulong ticket, double volume = 0.0);
   
   // Trailing stop management
   bool ApplyTrailingStop(ulong ticket, double currentPrice, double distance);
   
   // Partial close management
   bool ApplyPartialClose(ulong ticket, double closePercent);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPositionManager::CPositionManager(int magicNumber, bool trailingEnabled, 
                                 double trailingTrigger, double trailingStep,
                                 bool partialCloseEnabled, double partialClosePercent) {
   m_magicNumber = magicNumber;
   m_trailingEnabled = trailingEnabled;
   m_trailingTrigger = trailingTrigger;
   m_trailingStep = trailingStep;
   m_partialCloseEnabled = partialCloseEnabled;
   m_partialClosePercent = partialClosePercent;
   
   m_positionsTracked = false;
   
   // Initialize trade object
   m_trade.SetExpertMagicNumber(m_magicNumber);
}

//+------------------------------------------------------------------+
//| Initialize the position manager                                  |
//+------------------------------------------------------------------+
bool CPositionManager::Initialize() {
   InitializeTrailingStates();
   return true;
}

//+------------------------------------------------------------------+
//| Manage all open positions                                        |
//+------------------------------------------------------------------+
void CPositionManager::ManagePositions(const MqlTick &tick, CIndicatorManager *indMgr) {
   // Make sure trailing states are initialized
   if(!m_positionsTracked) {
      InitializeTrailingStates();
   }
   
   // Get all positions
   int total = PositionsTotal();
   
   for(int i = 0; i < total; i++) {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0 && IsOurPosition(ticket)) {
         ManageSinglePosition(ticket, tick, indMgr);
      }
   }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
bool CPositionManager::CloseAllPositions(string reason) {
   bool result = true;
   int total = PositionsTotal();
   
   // Must use reverse loop because closing positions changes their order
   for(int i = total - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0 && IsOurPosition(ticket)) {
         if(!ClosePosition(ticket)) {
            result = false;
            Print("Failed to close position #", ticket, " reason: ", reason);
         } else {
            Print("Closed position #", ticket, " reason: ", reason);
         }
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| Modify an existing position's SL and TP                          |
//+------------------------------------------------------------------+
bool CPositionManager::ModifyPosition(ulong ticket, double sl, double tp) {
   // Validate inputs
   if(ticket <= 0) {
      Print("Invalid ticket for position modification: ", ticket);
      return false;
   }
   
   // Check if this is our position
   if(!IsOurPosition(ticket)) {
      Print("Position #", ticket, " does not belong to this EA");
      return false;
   }
   
   // Select the position
   if(!m_positionInfo.SelectByTicket(ticket)) {
      Print("Failed to select position #", ticket);
      return false;
   }
   
   // Get current SL and TP
   double currentSL = m_positionInfo.StopLoss();
   double currentTP = m_positionInfo.TakeProfit();
   
   // Skip if no changes
   if(MathAbs(currentSL - sl) < 0.0001 && MathAbs(currentTP - tp) < 0.0001) {
      return true; // No change needed
   }
   
   // Normalize prices
   string symbolName = m_positionInfo.Symbol();
   sl = NormalizePrice(symbolName, sl);
   tp = NormalizePrice(symbolName, tp);
   
   // Perform modification
   if(!m_trade.PositionModify(ticket, sl, tp)) {
      Print("Failed to modify position #", ticket, ", error: ", m_trade.ResultRetcode(), 
            " (", m_trade.ResultRetcodeDescription(), ")");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Close a position (full or partial)                               |
//+------------------------------------------------------------------+
bool CPositionManager::ClosePosition(ulong ticket, double volume) {
   // Validate inputs
   if(ticket <= 0) {
      Print("Invalid ticket for position close: ", ticket);
      return false;
   }
   
   // Check if this is our position
   if(!IsOurPosition(ticket)) {
      Print("Position #", ticket, " does not belong to this EA");
      return false;
   }
   
   // Select the position
   if(!m_positionInfo.SelectByTicket(ticket)) {
      Print("Failed to select position #", ticket);
      return false;
   }
   
   // Determine close volume
   double posVolume = m_positionInfo.Volume();
   
   if(volume <= 0.0 || volume >= posVolume) {
      // Close entire position
      if(!m_trade.PositionClose(ticket)) {
         Print("Failed to close position #", ticket, ", error: ", m_trade.ResultRetcode(), 
               " (", m_trade.ResultRetcodeDescription(), ")");
         return false;
      }
   } else {
      // Partial close
      if(!m_trade.PositionClosePartial(ticket, volume)) {
         Print("Failed to partially close position #", ticket, ", error: ", m_trade.ResultRetcode(), 
               " (", m_trade.ResultRetcodeDescription(), ")");
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Apply trailing stop to a position                                |
//+------------------------------------------------------------------+
bool CPositionManager::ApplyTrailingStop(ulong ticket, double currentPrice, double distance) {
   // Validate inputs
   if(ticket <= 0 || currentPrice <= 0.0 || distance <= 0.0) {
      return false;
   }
   
   // Select the position
   if(!m_positionInfo.SelectByTicket(ticket)) {
      return false;
   }
   
   // Get position details
   double curSL = m_positionInfo.StopLoss();
   double curTP = m_positionInfo.TakeProfit();
   ENUM_POSITION_TYPE posType = m_positionInfo.PositionType();
   string symbolName = m_positionInfo.Symbol();
   
   // Calculate new stop loss
   double newSL = 0.0;
   
   if(posType == POSITION_TYPE_BUY) {
      newSL = currentPrice - distance;
      
      // Only move stop loss if it improves it
      if(curSL > 0.0 && newSL <= curSL) {
         return true; // No need to move SL
      }
   } else if(posType == POSITION_TYPE_SELL) {
      newSL = currentPrice + distance;
      
      // Only move stop loss if it improves it
      if(curSL > 0.0 && newSL >= curSL) {
         return true; // No need to move SL
      }
   } else {
      return false;
   }
   
   // Normalize price
   newSL = NormalizePrice(symbolName, newSL);
   
   // Apply new stop loss
   return ModifyPosition(ticket, newSL, curTP);
}

//+------------------------------------------------------------------+
//| Apply partial close to a position                                |
//+------------------------------------------------------------------+
bool CPositionManager::ApplyPartialClose(ulong ticket, double closePercent) {
   // Validate inputs
   if(ticket <= 0 || closePercent <= 0.0 || closePercent >= 100.0) {
      return false;
   }
   
   // Select the position
   if(!m_positionInfo.SelectByTicket(ticket)) {
      return false;
   }
   
   // Get position volume
   double posVol = m_positionInfo.Volume();
   
   // Calculate close volume
   double closeVolume = posVol * (closePercent / 100.0);
   
   // Get symbol properties
   string symbolName = m_positionInfo.Symbol();
   double minVol = SymbolInfoDouble(symbolName, SYMBOL_VOLUME_MIN);
   double stepVol = SymbolInfoDouble(symbolName, SYMBOL_VOLUME_STEP);
   
   // Make sure volume is valid
   closeVolume = MathFloor(closeVolume / stepVol) * stepVol;
   
   // Ensure minimum volume constraints
   if(closeVolume < minVol) {
      closeVolume = minVol;
   }
   
   // Ensure we don't close more than position volume
   closeVolume = MathMin(closeVolume, posVol);
   
   // Ensure the remaining volume meets minimum volume
   double remainingVolume = posVol - closeVolume;
   if(remainingVolume > 0 && remainingVolume < minVol) {
      // If remaining would be too small, close entire position
      closeVolume = posVol;
   }
   
   // Perform close
   return ClosePosition(ticket, closeVolume);
}

//+------------------------------------------------------------------+
//| Initialize trailing state structures                             |
//+------------------------------------------------------------------+
void CPositionManager::InitializeTrailingStates() {
   int totalPos = PositionsTotal();
   ArrayResize(m_trailingStates, totalPos);
   int stateCount = 0;
   
   for(int i = 0; i < totalPos; i++) {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket > 0 && IsOurPosition(ticket)) {
         // Initialize state for this position
         m_trailingStates[stateCount].ticket = ticket;
         m_trailingStates[stateCount].activationPrice = 0.0;
         m_trailingStates[stateCount].lastTrailPrice = 0.0;
         m_trailingStates[stateCount].trailingActive = false;
         
         stateCount++;
      }
   }
   
   if(stateCount < totalPos) {
      ArrayResize(m_trailingStates, stateCount);
   }
   
   m_positionsTracked = true;
}

//+------------------------------------------------------------------+
//| Manage a single position                                         |
//+------------------------------------------------------------------+
void CPositionManager::ManageSinglePosition(ulong ticket, const MqlTick &tick, 
                                          CIndicatorManager *indMgr) {
   // Select the position
   if(!m_positionInfo.SelectByTicket(ticket)) {
      return;
   }
   
   // Get position details
   ENUM_POSITION_TYPE posType = m_positionInfo.PositionType();
   double openPrice = m_positionInfo.PriceOpen();
   double curSL = m_positionInfo.StopLoss();
   double curTP = m_positionInfo.TakeProfit();
   double posVol = m_positionInfo.Volume();
   string symbolName = m_positionInfo.Symbol();
   
   // Get current price
   double curPrice = (posType == POSITION_TYPE_BUY) ? tick.bid : tick.ask;
   
   // Find trailing state for this position
   int stateIdx = -1;
   for(int i = 0; i < ArraySize(m_trailingStates); i++) {
      if(m_trailingStates[i].ticket == ticket) {
         stateIdx = i;
         break;
      }
   }
   
   // If state not found, initialize it
   if(stateIdx == -1) {
      int newSize = ArraySize(m_trailingStates) + 1;
      ArrayResize(m_trailingStates, newSize);
      stateIdx = newSize - 1;
      
      m_trailingStates[stateIdx].ticket = ticket;
      m_trailingStates[stateIdx].activationPrice = 0.0;
      m_trailingStates[stateIdx].lastTrailPrice = 0.0;
      m_trailingStates[stateIdx].trailingActive = false;
   }
   
   // Calculate profit in points
   double pointSize = SymbolInfoDouble(symbolName, SYMBOL_POINT);
   double profitPts = 0.0;
   
   if(posType == POSITION_TYPE_BUY) {
      profitPts = (curPrice - openPrice) / pointSize;
   } else {
      profitPts = (openPrice - curPrice) / pointSize;
   }
   
   // Apply trailing stop if enabled
   if(m_trailingEnabled) {
      // Check if trailing should be activated
      if(!m_trailingStates[stateIdx].trailingActive) {
         if(profitPts >= m_trailingTrigger) {
            m_trailingStates[stateIdx].trailingActive = true;
            m_trailingStates[stateIdx].activationPrice = curPrice;
            m_trailingStates[stateIdx].lastTrailPrice = curPrice;
            
            Print("Trailing stop activated for position #", ticket, 
                  " at ", DoubleToString(curPrice, _Digits));
         }
      }
      
      // Process trailing if active
      if(m_trailingStates[stateIdx].trailingActive) {
         double trailDist = m_trailingStep * pointSize;
         
         // Check if price moved enough to update trailing stop
         bool shouldUpdate = false;
         
         if(posType == POSITION_TYPE_BUY) {
            if(curPrice > m_trailingStates[stateIdx].lastTrailPrice + trailDist) {
               shouldUpdate = true;
            }
         } else {
            if(curPrice < m_trailingStates[stateIdx].lastTrailPrice - trailDist) {
               shouldUpdate = true;
            }
         }
         
         // Update trailing stop if needed
         if(shouldUpdate) {
            double newSL = 0.0;
            
            if(posType == POSITION_TYPE_BUY) {
               newSL = curPrice - trailDist;
            } else {
               newSL = curPrice + trailDist;
            }
            
            // Apply the new stop loss
            if(ModifyPosition(ticket, newSL, curTP)) {
               m_trailingStates[stateIdx].lastTrailPrice = curPrice;
               
               Print("Trailing stop updated for position #", ticket, 
                     " to ", DoubleToString(newSL, _Digits));
            }
         }
      }
   }
   
   // Apply partial close if enabled
   if(m_partialCloseEnabled) {
      // Check if we should apply partial close
      // Implementation will vary based on your strategy
      // Here's a simple example based on profit threshold
      double partialThreshold = m_trailingTrigger * 0.7; // 70% of trailing activation
      
      // Simplified example: close part when reaching threshold
      if(profitPts >= partialThreshold) {
         // Check if position was already partially closed
         if(posVol > 0.01) { // Using simple volume check, can be more sophisticated
            ApplyPartialClose(ticket, m_partialClosePercent);
         }
      }
   }
   
   // Advanced management based on indicators
   if(indMgr != NULL) {
      // Example: adjust TP based on volatility
      double atr = indMgr.GetATR();
      
      if(atr > 0) {
         // Adjust TP if volatility increased
         // Implementation depends on your specific strategy
      }
   }
}

//+------------------------------------------------------------------+
//| Check if a position belongs to our EA                            |
//+------------------------------------------------------------------+
bool CPositionManager::IsOurPosition(ulong ticket) {
   if(!m_positionInfo.SelectByTicket(ticket)) {
      return false;
   }
   
   long magic = m_positionInfo.Magic();
   return (magic == m_magicNumber);
}

//+------------------------------------------------------------------+
//| Normalize price to symbol digits                                 |
//+------------------------------------------------------------------+
double CPositionManager::NormalizePrice(string symbolName, double price) {
   int digits = (int)SymbolInfoInteger(symbolName, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}
