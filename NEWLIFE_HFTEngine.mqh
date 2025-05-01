//+------------------------------------------------------------------+
//|                    NEWLIFE_HFTEngine.mqh                         |
//|                  © 2025 H3NST7, www.H3NST7.com                   |
//|                                                                  |
//| Ultra-Stealthy High-Frequency Trading Engine for Gold            |
//+------------------------------------------------------------------+
#property copyright "© 2025 H3NST7"
#property link      "https://www.H3NST7.com"
#property strict

#include "NEWLIFE_Constants.mqh"
#include "NEWLIFE_Utilities.mqh"
#include "NEWLIFE_Indicators.mqh"
#include "NEWLIFE_OrderExecution.mqh"

// HFT Engine specific constants
#define HFT_TICK_BUFFER_SIZE       300    // Number of ticks to store in buffer
#define HFT_PRICE_LEVELS           100    // Number of price levels for volume profile
#define HFT_MIN_VOLUME             0.01   // Minimum trade volume
#define HFT_MAX_VOLUME             0.5    // Maximum trade volume
#define HFT_MAX_SPREAD_POINTS      45     // Maximum spread in points to trade
#define HFT_MIN_VOLATILITY         0.5    // Minimum volatility index to trade
#define HFT_MAX_VOLATILITY         3.0    // Maximum volatility index to trade
#define HFT_PROFIT_TARGET_POINTS   20     // Default profit target in points
#define HFT_STOP_LOSS_POINTS       15     // Default stop loss in points
#define HFT_DEFAULT_TIMEOUT_MS     1500   // Default timeout for trade execution (ms)
#define HFT_MIN_SUCCESS_RATE       55.0   // Minimum success rate to continue (%)
#define HFT_PROFIT_FACTOR_MIN      1.2    // Minimum profit factor to continue
#define HFT_TRADES_FOR_EVALUATION  10     // Number of trades before evaluating performance
#define HFT_COT_THRESHOLD          0.65   // Commitment of Traders threshold (0-1)
#define HFT_IMBALANCE_RATIO        1.75   // Buy/Sell imbalance ratio for signal
#define HFT_CLUSTER_DENSITY        2.5    // Density multiplier for liquidity clusters
#define HFT_ENTROPY_THRESHOLD      0.7    // Market efficiency/entropy threshold (0-1)
#define HFT_FOOTPRINT_LEVELS       10     // Number of price levels for footprint charts

// HFT Signal Structure
struct HFTSignal {
   ENUM_ORDER_TYPE type;            // Order type
   double entryPrice;               // Entry price
   double stopLoss;                 // Stop loss price
   double takeProfit;               // Take profit price
   double volume;                   // Position size
   double confidence;               // Signal confidence (0-100%)
   int signalStrength;              // Signal strength (1-10)
   string reason;                   // Signal reason/source
   datetime timestamp;              // Signal timestamp
};

// HFT Tick Data Structure
struct HFTTickData {
   double bid;                      // Bid price
   double ask;                      // Ask price
   double spread;                   // Spread in points
   datetime time;                   // Tick time
   double volume;                   // Tick volume
   double movingSpeed;              // Price moving speed
   double acceleration;             // Price acceleration
   double delta;                    // Buy/sell delta (pos = buying, neg = selling)
   int buyVolume;                   // Buying volume (estimated)
   int sellVolume;                  // Selling volume (estimated)
};

// HFT Performance Metrics Structure
struct HFTPerformanceMetrics {
   int totalTrades;                 // Total number of trades taken
   int winningTrades;               // Number of winning trades
   int losingTrades;                // Number of losing trades
   double totalProfit;              // Total profit in account currency
   double totalLoss;                // Total loss in account currency
   double largestWin;               // Largest winning trade
   double largestLoss;              // Largest losing trade
   double averageWin;               // Average winning trade
   double averageLoss;              // Average losing trade
   double winRate;                  // Win rate percentage
   double profitFactor;             // Profit factor
   double sharpeRatio;              // Sharpe ratio
   double maxDrawdown;              // Maximum drawdown
   double profitability;            // Overall profitability score
   datetime lastEvaluationTime;     // Time of last performance evaluation
};

// Price Level Structure for Market Profile
struct PriceLevel {
   double price;                    // Price level
   int totalVolume;                 // Total volume at this price
   int buyVolume;                   // Buy volume at this price
   int sellVolume;                  // Sell volume at this price
   double delta;                    // Delta (buyVolume - sellVolume)
   double imbalanceRatio;           // Imbalance ratio
   bool isSupport;                  // Is a support level
   bool isResistance;               // Is a resistance level
   bool isValueArea;                // Is within value area
   bool isLiquidityCluster;         // Is a liquidity cluster
};

// HFT Market Profile Structure
struct HFTMarketProfile {
   PriceLevel priceLevels[HFT_PRICE_LEVELS]; // Price levels with volume
   double volumeProfile[HFT_PRICE_LEVELS];   // Volume profile at different price levels
   double resistanceLevels[10];     // Detected resistance levels
   double supportLevels[10];        // Detected support levels
   double valueArea;                // Value area price
   double valueAreaHigh;            // Value area high
   double valueAreaLow;             // Value area low
   double pointOfControl;           // Point of control (highest volume price)
   double volatilityIndex;          // Current market volatility index
   double orderFlowImbalance;       // Order flow imbalance indicator
   bool isTrending;                 // Is market currently trending
   ENUM_TREND_DIRECTION trendDirection; // Current trend direction
   datetime lastUpdateTime;         // Last update time
   double liquidityClusterLevels[10]; // Key liquidity cluster price levels
   double absorbedVolume;           // Recently absorbed volume
   double auctionVolume;            // Volume in current auction
   double efficiency;               // Market efficiency ratio (0-1)
   double entropy;                  // Market entropy/randomness (0-1)
   ENUM_ORDER_FLOW_DIRECTION flowDirection; // Current order flow direction
};

// Trade/Order Context
struct OrderContext {
   double avgBidSize;               // Average bid order size
   double avgAskSize;               // Average ask order size
   double spreadEMA;                // Exponential moving average of spread
   double volumeEMA;                // Exponential moving average of volume
   double volumeStdDev;             // Standard deviation of volume
   double priceStdDev;              // Standard deviation of price
   double abnormalVolumeThreshold;  // Threshold for abnormal volume
   double normalizedBidStrength;    // Normalized bid strength (0-1)
   double normalizedAskStrength;    // Normalized ask strength (0-1)
   double buyPressure;              // Buy pressure indicator
   double sellPressure;             // Sell pressure indicator
   double quoteRefresh;             // Quote refresh rate
   double tradeAggressiveness;      // Aggressiveness of trades
};

// Market Regime State
struct MarketRegimeState {
   double trendStrength;            // Trend strength indicator
   double volatilityRegime;         // Volatility regime indicator
   double momentum;                 // Momentum indicator
   double meanReversionProb;        // Mean reversion probability
   double directionalBias;          // Directional bias indicator
   double noiseRatio;               // Noise ratio indicator
   double fractalDimension;         // Fractal dimension (market complexity)
   double chopIndex;                // Choppiness index
   double regimeChangeProb;         // Regime change probability
   string currentRegime;            // Current market regime description
};

// ML Prediction Model State
struct MLModelState {
   double directionProb;            // Price direction probability
   double volatilityPred;           // Volatility prediction
   double momentumPred;             // Momentum prediction
   double reversalProb;             // Reversal probability
   double breakoutProb;             // Breakout probability
   double supportBreakProb;         // Support break probability
   double resistanceBreakProb;      // Resistance break probability
   double consolidationProb;        // Consolidation probability
   double featureVector[20];        // Feature vector for ML model
   double predictionConfidence;     // Confidence in the prediction
   double predictionError;          // Prediction error estimate
};

//+------------------------------------------------------------------+
//| High-Frequency Trading Engine Class                              |
//+------------------------------------------------------------------+
class CHFTEngine {
private:
   // Core properties
   string m_symbol;                 // Trading symbol
   ENUM_HFT_STRATEGY m_strategy;    // Current HFT strategy
   ENUM_HFT_ENGINE_STATE m_state;   // Current engine state
   bool m_isInitialized;            // Initialization flag
   CLogger* m_logger;               // Logger reference
   CIndicatorManager* m_indMgr;     // Indicator manager reference
   COrderManager* m_orderMgr;       // Order manager reference
   int m_magicNumber;               // Magic number for trades
   
   // HFT Configuration
   double m_riskPercent;            // Risk per trade as percentage
   double m_minVolume;              // Minimum trade volume
   double m_maxVolume;              // Maximum trade volume
   double m_maxSpread;              // Maximum allowed spread
   int m_maxConsecLosses;           // Maximum allowed consecutive losses
   int m_maxTradesPerHour;          // Maximum trades per hour
   int m_timeoutMs;                 // Timeout for trade execution (ms)
   bool m_useAdaptiveParams;        // Use adaptive parameters flag
   bool m_enforceProfitTarget;      // Enforce profit target flag
   double m_minSuccessRate;         // Minimum success rate to continue
   double m_profitFactorMin;        // Minimum profit factor to continue
   double m_minProfitTarget;        // Minimum daily profit target
   double m_maxDailyLoss;           // Maximum daily loss limit
   
   // Runtime data
   HFTTickData m_tickBuffer[];      // Buffer of recent tick data
   int m_tickBufferSize;            // Size of tick buffer
   int m_tickBufferIndex;           // Current index in tick buffer
   HFTSignal m_lastSignal;          // Last generated signal
   HFTMarketProfile m_marketProfile;// Current market profile
   HFTPerformanceMetrics m_metrics; // Performance metrics
   OrderContext m_orderContext;     // Order context information
   MarketRegimeState m_regimeState; // Market regime state
   MLModelState m_mlModelState;     // ML prediction model state
   
   // Trade management
   int m_consecutiveLosses;         // Count of consecutive losses
   int m_tradesThisHour;            // Count of trades this hour
   int m_totalTrades;               // Total trades taken
   double m_dailyProfit;            // Current daily profit
   double m_dailyLoss;              // Current daily loss
   datetime m_lastTradeTime;        // Time of last trade
   datetime m_cooldownUntil;        // Cooldown period end time
   bool m_emergencyStop;            // Emergency stop flag
   
   // Price action analytics
   double m_regressionSlope;        // Current price linear regression slope
   double m_priceAcceleration;      // Price acceleration
   double m_volumeAcceleration;     // Volume acceleration
   double m_recentHighs[5];         // Recent swing highs
   double m_recentLows[5];          // Recent swing lows
   double m_volatilityRatio;        // Current volatility ratio
   double m_orderFlowRatio;         // Order flow ratio (buy/sell pressure)
   double m_footprintImbalance;     // Footprint chart imbalance
   double m_buyerAbsorption;        // Buyer absorption ratio
   double m_sellerAbsorption;       // Seller absorption ratio
   double m_volumetricVelocity;     // Volumetric price velocity
   double m_effortVsResult;         // Effort vs result ratio
   double m_abnormalVolumeRatio;    // Abnormal volume ratio
   double m_cumDeltaOscillator;     // Cumulative delta oscillator
   double m_orderFlowImbalance;     // Order flow imbalance
   double m_liquidityScore;         // Liquidity score at current price
   double m_orderFlowForce;         // Order flow force indicator
   double m_optimalTimeDecay;       // Optimal time decay factor
   double m_microTrendStrength;     // Micro trend strength
   
   // ML-based prediction data
   double m_directionProbability;   // Probability of direction (0-100%)
   double m_momentumStrength;       // Momentum strength indicator (0-100%)
   double m_reversalProbability;    // Reversal probability (0-100%)
   double m_volatilityPrediction;   // Predicted volatility change
   double m_supportBreakProb;       // Support break probability
   double m_resistanceBreakProb;    // Resistance break probability
   double m_rangeExpansionProb;     // Range expansion probability
   double m_consolidationProb;      // Consolidation probability
   double m_abnormalStateProb;      // Abnormal market state probability
   double m_predictionConfidence;   // Overall prediction confidence
   
   // Signal generation parameters
   int m_minimumTicksForSignal;     // Minimum ticks required for analysis
   double m_minDeltaThreshold;      // Minimum delta threshold
   double m_minVolumeThreshold;     // Minimum volume threshold
   double m_maxAdverseExcursion;    // Maximum adverse excursion allowed
   double m_aggressiveness;         // Strategy aggressiveness (0-1)
   double m_minConfidenceThreshold; // Minimum confidence for trade
   
   // Advanced analysis buffers
   double m_buyVolumeBuffer[];      // Buffer of buy volumes
   double m_sellVolumeBuffer[];     // Buffer of sell volumes
   double m_deltaBuffer[];          // Buffer of delta values
   double m_cumulativeDelta[];      // Cumulative delta buffer
   double m_volumeNodesX[];         // X coordinates of volume nodes
   double m_volumeNodesY[];         // Y coordinates of volume nodes
   double m_footprintMap[];         // Footprint chart data map
   
   // Private methods
   void UpdateTickBuffer(const MqlTick &tick);
   void AnalyzeTickData();
   void UpdateMarketProfile();
   bool GenerateSignal(HFTSignal &signal);
   bool ValidateSignal(HFTSignal &signal);
   bool ExecuteSignal(const HFTSignal &signal);
   double CalculatePositionSize(ENUM_ORDER_TYPE type, double entryPrice, double stopLoss);
   void CalculateStopLoss(ENUM_ORDER_TYPE type, double entryPrice, double &stopLoss);
   void CalculateTakeProfit(ENUM_ORDER_TYPE type, double entryPrice, double &takeProfit);
   void ManageOpenPositions();
   void UpdatePerformanceMetrics();
   void EvaluatePerformance();
   bool DetectLiquidityClusters();
   bool DetectOrderFlowImbalance();
   bool DetectMarketMicrostructure();
   bool DetectPriceAcceleration();
   bool IsMarketSuitable();
   void AdjustStrategyParameters();
   void RecordTradeResult(bool isWin, double profit);
   void UpdateDailyMetrics();
   void ComputeEfficiencyRatio();
   void IdentifySupportResistanceLevels();
   double ComputeMarketEntropy();
   void BuildVolumeProfile();
   void UpdateFootprintChart();
   void CalculateOrderFlowMetrics();
   void UpdateMLFeatureVector();
   void RunMLPredictions();
   void HandleSignificantLevelProximity();
   void ComputeFractalDimension();
   void CalculateOptimalEntryMetrics();
   void DetectAbnormalPatterns();
   void EstimateOrderFlowForce();
   void EvaluateMarketNoiseRatio();
   void CalculateVolumeAbsorption();
   void DetectLiquiditySweeps();
   void IdentifyOptimalHedgeRatio();
   void UpdateMarketRegimeState();
   void ClassifyOrderFlowDirection();
   void BuildCointegrationMatrix();
   void DetectMarketMakerActivity();
   bool CalculateLinearRegression(int lookback, double &slope);
   
   // Strategy implementations
   bool TickScalperStrategy(HFTSignal &signal);
   bool VolatilityBreakoutStrategy(HFTSignal &signal);
   bool MomentumBurstStrategy(HFTSignal &signal);
   bool LiquidityHunterStrategy(HFTSignal &signal);
   bool SpreadCaptureStrategy(HFTSignal &signal);
   bool AdaptiveStrategy(HFTSignal &signal);
   
public:
   // Constructor/Destructor
   CHFTEngine(string symbol, ENUM_HFT_STRATEGY strategy, 
              CLogger* logger, CIndicatorManager* indMgr, 
              COrderManager* orderMgr, int magicNumber);
   ~CHFTEngine();
   
   // Initialization and state management
   bool Initialize(double riskPercent, double maxSpread);
   void Shutdown();
   void SetState(ENUM_HFT_ENGINE_STATE state);
   ENUM_HFT_ENGINE_STATE GetState() const { return m_state; }
   
   // Main processing methods
   void ProcessTick(const MqlTick &tick);
   bool ShouldActivate();
   void ResetPerformanceMetrics();
   
   // Configuration methods
   void SetRiskParameters(double riskPercent, double maxDailyLoss);
   void SetVolumeConstraints(double minVolume, double maxVolume);
   void SetTradeConstraints(int maxTradesPerHour, int maxConsecLosses);
   void SetTimeoutMs(int timeoutMs) { m_timeoutMs = timeoutMs; }
   void SetStrategy(ENUM_HFT_STRATEGY strategy);
   
   // Performance and status methods
   HFTPerformanceMetrics GetPerformanceMetrics() const { return m_metrics; }
   double GetProfitability() const { return m_metrics.profitability; }
   bool IsReadyToTrade() const;
   void DumpStatistics();
   string GetStateAsString() const;
   string GetStrategyName() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CHFTEngine::CHFTEngine(string symbol, ENUM_HFT_STRATEGY strategy, 
                       CLogger* logger, CIndicatorManager* indMgr, 
                       COrderManager* orderMgr, int magicNumber) {
   m_symbol = symbol;
   m_strategy = strategy;
   m_state = HFT_STATE_INACTIVE;
   m_isInitialized = false;
   m_logger = logger;
   m_indMgr = indMgr;
   m_orderMgr = orderMgr;
   m_magicNumber = magicNumber;
   
   // Default configuration
   m_riskPercent = 0.5;  // Lower risk percent for HFT
   m_minVolume = HFT_MIN_VOLUME;
   m_maxVolume = HFT_MAX_VOLUME;
   m_maxSpread = HFT_MAX_SPREAD_POINTS;
   m_maxConsecLosses = 3;
   m_maxTradesPerHour = 10;
   m_timeoutMs = HFT_DEFAULT_TIMEOUT_MS;
   m_useAdaptiveParams = true;
   m_enforceProfitTarget = true;
   m_minSuccessRate = HFT_MIN_SUCCESS_RATE;
   m_profitFactorMin = HFT_PROFIT_FACTOR_MIN;
   m_minProfitTarget = 1.0;  // 1% daily target
   m_maxDailyLoss = 2.0;     // 2% max daily loss
   
   // Signal generation parameters
   m_minimumTicksForSignal = 20;
   m_minDeltaThreshold = 0.3;
   m_minVolumeThreshold = 10;
   m_maxAdverseExcursion = 0.5;
   m_aggressiveness = 0.5;
   m_minConfidenceThreshold = 65.0;
   
   // Runtime initialization
   m_tickBufferSize = HFT_TICK_BUFFER_SIZE;
   m_tickBufferIndex = 0;
   ArrayResize(m_tickBuffer, m_tickBufferSize);
   ZeroMemory(m_lastSignal);
   ZeroMemory(m_marketProfile);
   ZeroMemory(m_metrics);
   ZeroMemory(m_orderContext);
   ZeroMemory(m_regimeState);
   ZeroMemory(m_mlModelState);
   
   // Trade management initialization
   m_consecutiveLosses = 0;
   m_tradesThisHour = 0;
   m_totalTrades = 0;
   m_dailyProfit = 0.0;
   m_dailyLoss = 0.0;
   m_lastTradeTime = 0;
   m_cooldownUntil = 0;
   m_emergencyStop = false;
   
   // Analytics initialization
   m_regressionSlope = 0.0;
   m_priceAcceleration = 0.0;
   m_volumeAcceleration = 0.0;
   m_volatilityRatio = 1.0;
   m_orderFlowRatio = 1.0;
   m_footprintImbalance = 0.0;
   m_buyerAbsorption = 0.0;
   m_sellerAbsorption = 0.0;
   m_volumetricVelocity = 0.0;
   m_effortVsResult = 1.0;
   m_abnormalVolumeRatio = 1.0;
   m_cumDeltaOscillator = 0.0;
   m_orderFlowImbalance = 0.0;
   m_liquidityScore = 50.0;
   m_orderFlowForce = 0.0;
   m_microTrendStrength = 0.0;
   
   // ML prediction initialization
   m_directionProbability = 50.0;
   m_momentumStrength = 0.0;
   m_reversalProbability = 0.0;
   m_volatilityPrediction = 0.0;
   m_supportBreakProb = 0.0;
   m_resistanceBreakProb = 0.0;
   m_rangeExpansionProb = 0.0;
   m_consolidationProb = 0.0;
   m_abnormalStateProb = 0.0;
   m_predictionConfidence = 0.0;
   
   // Arrays initialization
   ArrayResize(m_buyVolumeBuffer, HFT_TICK_BUFFER_SIZE);
   ArrayResize(m_sellVolumeBuffer, HFT_TICK_BUFFER_SIZE);
   ArrayResize(m_deltaBuffer, HFT_TICK_BUFFER_SIZE);
   ArrayResize(m_cumulativeDelta, HFT_TICK_BUFFER_SIZE);
   ArrayResize(m_volumeNodesX, HFT_PRICE_LEVELS);
   ArrayResize(m_volumeNodesY, HFT_PRICE_LEVELS);
   ArrayResize(m_footprintMap, HFT_PRICE_LEVELS * HFT_FOOTPRINT_LEVELS);
   
   ArrayInitialize(m_buyVolumeBuffer, 0);
   ArrayInitialize(m_sellVolumeBuffer, 0);
   ArrayInitialize(m_deltaBuffer, 0);
   ArrayInitialize(m_cumulativeDelta, 0);
   ArrayInitialize(m_volumeNodesX, 0);
   ArrayInitialize(m_volumeNodesY, 0);
   ArrayInitialize(m_footprintMap, 0);
   
   // Initialize recent highs and lows
   for(int i = 0; i < 5; i++) {
      m_recentHighs[i] = 0;
      m_recentLows[i] = 0;
   }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CHFTEngine::~CHFTEngine() {
   // Clean up resources
   if(m_isInitialized) {
      Shutdown();
   }
   
   // Free arrays
   ArrayFree(m_tickBuffer);
   ArrayFree(m_buyVolumeBuffer);
   ArrayFree(m_sellVolumeBuffer);
   ArrayFree(m_deltaBuffer);
   ArrayFree(m_cumulativeDelta);
   ArrayFree(m_volumeNodesX);
   ArrayFree(m_volumeNodesY);
   ArrayFree(m_footprintMap);
}

//+------------------------------------------------------------------+
//| Initialize the HFT Engine                                        |
//+------------------------------------------------------------------+
bool CHFTEngine::Initialize(double riskPercent, double maxSpread) {
   if(m_isInitialized) return true;
   
   if(m_logger == NULL) {
      Print("HFTEngine Error: Logger is NULL");
      return false;
   }
   
   m_logger.Info("Initializing HFT Engine for " + m_symbol);
   
   // Set risk parameters
   m_riskPercent = riskPercent;
   m_maxSpread = maxSpread;
   
   // Initialize tick buffer
   for(int i = 0; i < m_tickBufferSize; i++) {
      m_tickBuffer[i].bid = 0;
      m_tickBuffer[i].ask = 0;
      m_tickBuffer[i].spread = 0;
      m_tickBuffer[i].time = 0;
      m_tickBuffer[i].volume = 0;
      m_tickBuffer[i].movingSpeed = 0;
      m_tickBuffer[i].acceleration = 0;
      m_tickBuffer[i].delta = 0;
      m_tickBuffer[i].buyVolume = 0;
      m_tickBuffer[i].sellVolume = 0;
   }
   
   // Initialize market profile
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      m_marketProfile.priceLevels[i].price = 0;
      m_marketProfile.priceLevels[i].totalVolume = 0;
      m_marketProfile.priceLevels[i].buyVolume = 0;
      m_marketProfile.priceLevels[i].sellVolume = 0;
      m_marketProfile.priceLevels[i].delta = 0;
      m_marketProfile.priceLevels[i].imbalanceRatio = 1.0;
      m_marketProfile.priceLevels[i].isSupport = false;
      m_marketProfile.priceLevels[i].isResistance = false;
      m_marketProfile.priceLevels[i].isValueArea = false;
      m_marketProfile.priceLevels[i].isLiquidityCluster = false;
      
      m_marketProfile.volumeProfile[i] = 0;
   }
   
   // Initialize support/resistance levels
   for(int i = 0; i < 10; i++) {
      m_marketProfile.supportLevels[i] = 0;
      m_marketProfile.resistanceLevels[i] = 0;
      m_marketProfile.liquidityClusterLevels[i] = 0;
   }
   
   // Set initial market profile
   m_marketProfile.valueArea = 0;
   m_marketProfile.valueAreaHigh = 0;
   m_marketProfile.valueAreaLow = 0;
   m_marketProfile.pointOfControl = 0;
   m_marketProfile.volatilityIndex = 1.0;
   m_marketProfile.orderFlowImbalance = 0;
   m_marketProfile.isTrending = false;
   m_marketProfile.trendDirection = TREND_NEUTRAL;
   m_marketProfile.lastUpdateTime = 0;
   m_marketProfile.absorbedVolume = 0;
   m_marketProfile.auctionVolume = 0;
   m_marketProfile.efficiency = 0.5;
   m_marketProfile.entropy = 0.5;
   m_marketProfile.flowDirection = ORDER_FLOW_NEUTRAL;
   
   // Set initial order context
   m_orderContext.avgBidSize = 0;
   m_orderContext.avgAskSize = 0;
   m_orderContext.spreadEMA = 0;
   m_orderContext.volumeEMA = 0;
   m_orderContext.volumeStdDev = 0;
   m_orderContext.priceStdDev = 0;
   m_orderContext.abnormalVolumeThreshold = 0;
   m_orderContext.normalizedBidStrength = 0.5;
   m_orderContext.normalizedAskStrength = 0.5;
   m_orderContext.buyPressure = 0;
   m_orderContext.sellPressure = 0;
   m_orderContext.quoteRefresh = 0;
   m_orderContext.tradeAggressiveness = 0;
   
   // Set initial performance metrics
   m_metrics.totalTrades = 0;
   m_metrics.winningTrades = 0;
   m_metrics.losingTrades = 0;
   m_metrics.totalProfit = 0.0;
   m_metrics.totalLoss = 0.0;
   m_metrics.largestWin = 0.0;
   m_metrics.largestLoss = 0.0;
   m_metrics.averageWin = 0.0;
   m_metrics.averageLoss = 0.0;
   m_metrics.winRate = 0.0;
   m_metrics.profitFactor = 0.0;
   m_metrics.sharpeRatio = 0.0;
   m_metrics.maxDrawdown = 0.0;
   m_metrics.profitability = 0.0;
   m_metrics.lastEvaluationTime = TimeCurrent();
   
   // Set initial state
   m_state = HFT_STATE_MONITORING;
   m_isInitialized = true;
   
   m_logger.Info("HFT Engine initialized successfully. Strategy: " + GetStrategyName());
   return true;
}

//+------------------------------------------------------------------+
//| Calculate linear regression slope for specified lookback period  |
//+------------------------------------------------------------------+
bool CHFTEngine::CalculateLinearRegression(int lookback, double &slope) {
   double x[100], y[100];
   int count = 0;
   int startIdx = m_tickBufferIndex;
   
   for(int i = 0; i < lookback && i < 100; i++) {
      int idx = (startIdx - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      x[count] = count;
      y[count] = (m_tickBuffer[idx].bid + m_tickBuffer[idx].ask) / 2.0;
      count++;
   }
   
   if(count < lookback / 2) return false; // Not enough data
   
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   
   for(int i = 0; i < count; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
   }
   
   double avgX = sumX / count;
   double avgY = sumY / count;
   
   // Calculate linear regression slope
   double denominator = sumX2 - count * avgX * avgX;
   if(MathAbs(denominator) < 0.00000001) return false; // Avoid division by near-zero
   
   slope = (sumXY - count * avgX * avgY) / denominator;
   return true;
}

//+------------------------------------------------------------------+
//| Shut down the HFT Engine                                         |
//+------------------------------------------------------------------+
void CHFTEngine::Shutdown() {
   if(!m_isInitialized) return;
   
   m_logger.Info("Shutting down HFT Engine");
   
   // Close any open positions if necessary
   // (Implementation would depend on how positions are tracked)
   
   // Set state to inactive
   m_state = HFT_STATE_INACTIVE;
   m_isInitialized = false;
   
   // Dump final statistics
   DumpStatistics();
   
   m_logger.Info("HFT Engine shut down successfully");
}

//+------------------------------------------------------------------+
//| Process a new tick                                               |
//+------------------------------------------------------------------+
void CHFTEngine::ProcessTick(const MqlTick &tick) {
   if(!m_isInitialized || m_state == HFT_STATE_INACTIVE || m_state == HFT_STATE_ERROR) {
      return;
   }
   
   // Update the tick buffer
   UpdateTickBuffer(tick);
   
   // If in cooldown period, check if it's over
   if(m_state == HFT_STATE_COOLDOWN) {
      if(TimeCurrent() >= m_cooldownUntil) {
         m_state = HFT_STATE_MONITORING;
         m_logger.Debug("HFT Engine cooldown period ended, resuming monitoring");
      } else {
         return; // Still in cooldown
      }
   }
   
   // Analyze tick data
   AnalyzeTickData();
   
   // Periodically update market profile (every 10 ticks)
   if(m_tickBufferIndex % 10 == 0) {
      UpdateMarketProfile();
      
      // Update ML predictions
      UpdateMLFeatureVector();
      RunMLPredictions();
   }
   
   // Manage existing positions (every tick)
   ManageOpenPositions();
   
   // If not in trading state, check if we should be
   if(m_state == HFT_STATE_MONITORING) {
      // Check if market conditions are suitable for HFT
      if(IsMarketSuitable()) {
         m_state = HFT_STATE_TRADING;
         m_logger.Info("HFT Engine entering trading state. Market conditions suitable.");
      }
   }
   
   // If in trading state, look for signals
   if(m_state == HFT_STATE_TRADING) {
      // Check if we've hit trade limits
      if(m_tradesThisHour >= m_maxTradesPerHour) {
         m_logger.Debug("HFT Engine max trades per hour reached, entering cooldown");
         m_state = HFT_STATE_COOLDOWN;
         m_cooldownUntil = TimeCurrent() + 600; // 10 minute cooldown
         return;
      }
      
      if(m_consecutiveLosses >= m_maxConsecLosses) {
         m_logger.Warn("HFT Engine max consecutive losses reached, entering cooldown");
         m_state = HFT_STATE_COOLDOWN;
         m_cooldownUntil = TimeCurrent() + 1800; // 30 minute cooldown
         return;
      }
      
      // Generate trading signal
      HFTSignal signal;
      if(GenerateSignal(signal)) {
         if(ValidateSignal(signal)) {
            // Execute the signal
            if(ExecuteSignal(signal)) {
               m_lastSignal = signal;
               m_lastTradeTime = TimeCurrent();
               m_tradesThisHour++;
               m_totalTrades++;
               
               m_logger.Info("HFT Engine executed trade: " + EnumToString(signal.type) + 
                           ", Entry: " + DoubleToString(signal.entryPrice, SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) +
                           ", SL: " + DoubleToString(signal.stopLoss, SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) +
                           ", TP: " + DoubleToString(signal.takeProfit, SymbolInfoInteger(m_symbol, SYMBOL_DIGITS)) +
                           ", Volume: " + DoubleToString(signal.volume, 2) +
                           ", Reason: " + signal.reason);
            }
         }
      }
      
      // Periodically evaluate performance
      if(m_metrics.totalTrades >= HFT_TRADES_FOR_EVALUATION && 
         TimeCurrent() - m_metrics.lastEvaluationTime >= 600) { // Every 10 minutes
         EvaluatePerformance();
      }
   }
}

//+------------------------------------------------------------------+
//| Update the tick buffer with new tick data                        |
//+------------------------------------------------------------------+
void CHFTEngine::UpdateTickBuffer(const MqlTick &tick) {
   // Calculate the spread in points
   double spread = (tick.ask - tick.bid) / SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   
   // Update buffer index (circular buffer)
   m_tickBufferIndex = (m_tickBufferIndex + 1) % m_tickBufferSize;
   
   // Create bid/ask delta to determine direction
   double delta = 0.0;
   int buyVolume = 0, sellVolume = 0;
   
   // Previous tick for comparison
   int prevIndex = (m_tickBufferIndex - 1 + m_tickBufferSize) % m_tickBufferSize;
   
   // If we have a previous tick, determine direction and volume attribution
   if(m_tickBuffer[prevIndex].time > 0) {
      double prevBid = m_tickBuffer[prevIndex].bid;
      double prevAsk = m_tickBuffer[prevIndex].ask;
      double midPrice = (tick.bid + tick.ask) / 2.0;
      double prevMidPrice = (prevBid + prevAsk) / 2.0;
      
      // Determine if price moved up or down
      if(midPrice > prevMidPrice) {
         // Upward movement - likely buy trades at ask
         delta = tick.volume;
         buyVolume = (int)tick.volume;
         sellVolume = 0;
      } 
      else if(midPrice < prevMidPrice) {
         // Downward movement - likely sell trades at bid
         delta = -tick.volume;
         buyVolume = 0;
         sellVolume = (int)tick.volume;
      }
      else {
         // No price change - split the volume
         delta = 0;
         buyVolume = (int)(tick.volume / 2);
         sellVolume = (int)(tick.volume - buyVolume);
      }
   }
   
   // Store the tick data
   m_tickBuffer[m_tickBufferIndex].bid = tick.bid;
   m_tickBuffer[m_tickBufferIndex].ask = tick.ask;
   m_tickBuffer[m_tickBufferIndex].spread = spread;
   m_tickBuffer[m_tickBufferIndex].time = tick.time;
   m_tickBuffer[m_tickBufferIndex].volume = tick.volume;
   m_tickBuffer[m_tickBufferIndex].delta = delta;
   m_tickBuffer[m_tickBufferIndex].buyVolume = buyVolume;
   m_tickBuffer[m_tickBufferIndex].sellVolume = sellVolume;
   
   // Store delta and volumes in their respective buffers
   m_deltaBuffer[m_tickBufferIndex] = delta;
   m_buyVolumeBuffer[m_tickBufferIndex] = buyVolume;
   m_sellVolumeBuffer[m_tickBufferIndex] = sellVolume;
   
   // Update cumulative delta
   if(m_tickBufferIndex == 0) {
      m_cumulativeDelta[m_tickBufferIndex] = delta;
   } else {
      m_cumulativeDelta[m_tickBufferIndex] = m_cumulativeDelta[prevIndex] + delta;
   }
   
   // Calculate moving speed and acceleration (if enough data)
   if(m_tickBuffer[prevIndex].time > 0) {
      double prevBid = m_tickBuffer[prevIndex].bid;
      double prevAsk = m_tickBuffer[prevIndex].ask;
      double prevSpeed = m_tickBuffer[prevIndex].movingSpeed;
      
      // Average of bid and ask changes
      double priceDelta = ((tick.bid - prevBid) + (tick.ask - prevAsk)) / 2.0;
      
      // Calculate speed (points per tick)
      double speed = priceDelta / SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      m_tickBuffer[m_tickBufferIndex].movingSpeed = speed;
      
      // Calculate acceleration (change in speed)
      m_tickBuffer[m_tickBufferIndex].acceleration = speed - prevSpeed;
   }
}

//+------------------------------------------------------------------+
//| Analyze tick data for patterns and trends                        |
//+------------------------------------------------------------------+
void CHFTEngine::AnalyzeTickData() {
   // This function analyzes tick data for trading insights
   
   // Skip if not enough data
   if(m_tickBuffer[m_tickBufferIndex].time == 0) return;
   
   // Calculate price regression slope using recent ticks
   double x[30], y[30];
   int count = 0;
   int startIdx = m_tickBufferIndex;
   
   for(int i = 0; i < 30; i++) {
      int idx = (startIdx - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      x[count] = count;
      y[count] = (m_tickBuffer[idx].bid + m_tickBuffer[idx].ask) / 2.0;
      count++;
   }
   
   if(count >= 15) { // Need enough data points
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      
      for(int i = 0; i < count; i++) {
         sumX += x[i];
         sumY += y[i];
         sumXY += x[i] * y[i];
         sumX2 += x[i] * x[i];
      }
      
      double avgX = sumX / count;
      double avgY = sumY / count;
      
      // Calculate linear regression slope
      if(sumX2 - count * avgX * avgX != 0) {
         m_regressionSlope = (sumXY - count * avgX * avgY) / (sumX2 - count * avgX * avgX);
      }
   }
   
   // Calculate average price acceleration over last 20 ticks
   double sumAccel = 0;
   int accelCount = 0;
   
   for(int i = 0; i < 20; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      sumAccel += m_tickBuffer[idx].acceleration;
      accelCount++;
   }
   
   if(accelCount > 0) {
      m_priceAcceleration = sumAccel / accelCount;
   }
   
   // Calculate volume acceleration (rate of change of volume)
   double earlyVolume = 0, recentVolume = 0;
   int earlyCount = 0, recentCount = 0;
   
   // Early volume (ticks 20-40 ago)
   for(int i = 20; i < 40; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      earlyVolume += m_tickBuffer[idx].volume;
      earlyCount++;
   }
   
   // Recent volume (last 20 ticks)
   for(int i = 0; i < 20; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      recentVolume += m_tickBuffer[idx].volume;
      recentCount++;
   }
   
   // Calculate volume acceleration
   if(earlyCount > 0 && recentCount > 0) {
      double avgEarlyVolume = earlyVolume / earlyCount;
      double avgRecentVolume = recentVolume / recentCount;
      
      m_volumeAcceleration = (avgRecentVolume - avgEarlyVolume) / avgEarlyVolume;
   }
   
   // Calculate volatility ratio (recent vs earlier volatility)
   double recentVolatility = 0.0;
   double oldVolatility = 0.0;
   
   // Recent volatility (last 20 ticks)
   double sumRecentSpeed = 0;
   int recentSpeedCount = 0;
   
   for(int i = 0; i < 20; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      sumRecentSpeed += MathAbs(m_tickBuffer[idx].movingSpeed);
      recentSpeedCount++;
   }
   
   if(recentSpeedCount > 0) {
      recentVolatility = sumRecentSpeed / recentSpeedCount;
   }
   
   // Older volatility (ticks 20-40 ago)
   double sumOldSpeed = 0;
   int oldSpeedCount = 0;
   
   for(int i = 20; i < 40; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      sumOldSpeed += MathAbs(m_tickBuffer[idx].movingSpeed);
      oldSpeedCount++;
   }
   
   if(oldSpeedCount > 0) {
      oldVolatility = sumOldSpeed / oldSpeedCount;
   }
   
   // Avoid division by zero
   if(oldVolatility > 0) {
      m_volatilityRatio = recentVolatility / oldVolatility;
   } else {
      m_volatilityRatio = 1.0;
   }
   
   // Calculate order flow ratio (buy/sell pressure)
   double totalBuyVolume = 0, totalSellVolume = 0;
   
   for(int i = 0; i < 50; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      totalBuyVolume += m_tickBuffer[idx].buyVolume;
      totalSellVolume += m_tickBuffer[idx].sellVolume;
   }
   
   // Avoid division by zero
   if(totalSellVolume > 0) {
      m_orderFlowRatio = totalBuyVolume / totalSellVolume;
   } else {
      m_orderFlowRatio = 1.0;
   }
   
   // Calculate cumulative delta oscillator
   double maxDelta = -999999, minDelta = 999999;
   
   for(int i = 0; i < 100; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      double cumDelta = m_cumulativeDelta[idx];
      
      if(cumDelta > maxDelta) maxDelta = cumDelta;
      if(cumDelta < minDelta) minDelta = cumDelta;
   }
   
   // Normalize current delta position
   double range = maxDelta - minDelta;
   if(range > 0) {
      double currentDelta = m_cumulativeDelta[m_tickBufferIndex];
      m_cumDeltaOscillator = (currentDelta - minDelta) / range;
   } else {
      m_cumDeltaOscillator = 0.5;
   }
   
   // Calculate buying/selling absorption
   CalculateVolumeAbsorption();
   
   // Calculate microtrend strength
   double shortSlope = 0, longSlope = 0;
   
   // Short-term trend (last 10 ticks)
   if(CalculateLinearRegression(10, shortSlope)) {
      // Long-term trend (last 50 ticks)
      if(CalculateLinearRegression(50, longSlope)) {
         // Compare short and long-term trends
         if(shortSlope * longSlope > 0) {
            // Same direction - strong trend
            m_microTrendStrength = MathAbs(shortSlope) * 1000;
         } else {
            // Opposite direction - potential reversal
            m_microTrendStrength = -MathAbs(shortSlope) * 1000;
         }
      }
   }
   
   // Detect significant price levels in proximity
   HandleSignificantLevelProximity();
   
   // Calculate order flow force
   EstimateOrderFlowForce();
}

//+------------------------------------------------------------------+
//| Update the market profile data                                   |
//+------------------------------------------------------------------+
void CHFTEngine::UpdateMarketProfile() {
   // This function builds a market profile from tick data
   
   // First, reset the existing volume profile
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      m_marketProfile.volumeProfile[i] = 0;
   }
   
   // Get price range from tick data
   double minPrice = DBL_MAX;
   double maxPrice = DBL_MIN;
   double totalVolume = 0;
   
   // Find min/max prices and total volume
   for(int i = 0; i < m_tickBufferSize; i++) {
      if(m_tickBuffer[i].time == 0) continue;
      
      double midPrice = (m_tickBuffer[i].bid + m_tickBuffer[i].ask) / 2.0;
      
      if(midPrice < minPrice) minPrice = midPrice;
      if(midPrice > maxPrice) maxPrice = midPrice;
      
      totalVolume += m_tickBuffer[i].volume;
   }
   
   // If not enough data, skip
   if(maxPrice <= minPrice || totalVolume <= 0) {
      return;
   }
   
   // Build the volume profile
   double priceStep = (maxPrice - minPrice) / (HFT_PRICE_LEVELS - 1);
   
   // Initialize price levels
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      double levelPrice = minPrice + i * priceStep;
      m_marketProfile.priceLevels[i].price = levelPrice;
      m_marketProfile.priceLevels[i].totalVolume = 0;
      m_marketProfile.priceLevels[i].buyVolume = 0;
      m_marketProfile.priceLevels[i].sellVolume = 0;
      m_marketProfile.priceLevels[i].delta = 0;
      m_marketProfile.priceLevels[i].imbalanceRatio = 1.0;
      m_marketProfile.priceLevels[i].isSupport = false;
      m_marketProfile.priceLevels[i].isResistance = false;
      m_marketProfile.priceLevels[i].isValueArea = false;
      m_marketProfile.priceLevels[i].isLiquidityCluster = false;
      
      m_volumeNodesX[i] = levelPrice;
      m_volumeNodesY[i] = 0;
   }
   
   // Distribute volume to price levels
   for(int i = 0; i < m_tickBufferSize; i++) {
      if(m_tickBuffer[i].time == 0) continue;
      
      double midPrice = (m_tickBuffer[i].bid + m_tickBuffer[i].ask) / 2.0;
      int level = (int)MathRound((midPrice - minPrice) / priceStep);
      
      // Ensure level is within bounds
      if(level >= 0 && level < HFT_PRICE_LEVELS) {
         m_marketProfile.priceLevels[level].totalVolume += (int)m_tickBuffer[i].volume;
         m_marketProfile.priceLevels[level].buyVolume += m_tickBuffer[i].buyVolume;
         m_marketProfile.priceLevels[level].sellVolume += m_tickBuffer[i].sellVolume;
         m_marketProfile.volumeProfile[level] += m_tickBuffer[i].volume;
         m_volumeNodesY[level] += m_tickBuffer[i].volume;
      }
   }
   
   // Calculate delta and imbalance ratio for each price level
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      if(m_marketProfile.priceLevels[i].totalVolume > 0) {
         m_marketProfile.priceLevels[i].delta = 
            m_marketProfile.priceLevels[i].buyVolume - m_marketProfile.priceLevels[i].sellVolume;
         
         // Calculate imbalance ratio (avoid division by zero)
         if(m_marketProfile.priceLevels[i].sellVolume > 0) {
            m_marketProfile.priceLevels[i].imbalanceRatio = 
               (double)m_marketProfile.priceLevels[i].buyVolume / m_marketProfile.priceLevels[i].sellVolume;
         } else if(m_marketProfile.priceLevels[i].buyVolume > 0) {
            m_marketProfile.priceLevels[i].imbalanceRatio = 999.0; // Strongly bullish
         } else {
            m_marketProfile.priceLevels[i].imbalanceRatio = 1.0; // Neutral (shouldn't happen)
         }
      }
   }
   
   // Find point of control (price level with highest volume)
   int pocIndex = 0;
   double maxLevelVolume = 0;
   
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      if(m_marketProfile.volumeProfile[i] > maxLevelVolume) {
         maxLevelVolume = m_marketProfile.volumeProfile[i];
         pocIndex = i;
      }
   }
   
   m_marketProfile.pointOfControl = m_marketProfile.priceLevels[pocIndex].price;
   
   // Calculate value area (70% of total volume)
   double valueAreaVolume = totalVolume * 0.7;
   double currentVolume = maxLevelVolume;
   int vaHighIndex = pocIndex;
   int vaLowIndex = pocIndex;
   
   // Expand the value area until it contains enough volume
   while(currentVolume < valueAreaVolume && (vaHighIndex < HFT_PRICE_LEVELS - 1 || vaLowIndex > 0)) {
      double volumeAbove = (vaHighIndex < HFT_PRICE_LEVELS - 1) ? 
                          m_marketProfile.volumeProfile[vaHighIndex + 1] : 0;
                          
      double volumeBelow = (vaLowIndex > 0) ? 
                          m_marketProfile.volumeProfile[vaLowIndex - 1] : 0;
      
      if(volumeAbove >= volumeBelow && vaHighIndex < HFT_PRICE_LEVELS - 1) {
         vaHighIndex++;
         currentVolume += volumeAbove;
      } else if(vaLowIndex > 0) {
         vaLowIndex--;
         currentVolume += volumeBelow;
      }
   }
   
   m_marketProfile.valueAreaHigh = m_marketProfile.priceLevels[vaHighIndex].price;
   m_marketProfile.valueAreaLow = m_marketProfile.priceLevels[vaLowIndex].price;
   m_marketProfile.valueArea = (m_marketProfile.valueAreaHigh + m_marketProfile.valueAreaLow) / 2.0;
   
   // Mark price levels in value area
   for(int i = vaLowIndex; i <= vaHighIndex; i++) {
      m_marketProfile.priceLevels[i].isValueArea = true;
   }
   
   // Identify support and resistance levels
   IdentifySupportResistanceLevels();
   
   // Detect liquidity clusters
   DetectLiquidityClusters();
   
   // Update footprint chart (order flow chart)
   UpdateFootprintChart();
   
   // Calculate market efficiency ratio
   ComputeEfficiencyRatio();
   
   // Compute market entropy
   m_marketProfile.entropy = ComputeMarketEntropy();
   
   // Calculate order flow metrics
   CalculateOrderFlowMetrics();
   
   // Detect liquidity sweeps (stop hunts)
   DetectLiquiditySweeps();
   
   // Classify current order flow direction
   ClassifyOrderFlowDirection();
   
   // Update market regime state
   UpdateMarketRegimeState();
   
   // Update timestamp
   m_marketProfile.lastUpdateTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Identify support and resistance levels                           |
//+------------------------------------------------------------------+
void CHFTEngine::IdentifySupportResistanceLevels() {
   // Reset existing levels
   for(int i = 0; i < 10; i++) {
      m_marketProfile.supportLevels[i] = 0;
      m_marketProfile.resistanceLevels[i] = 0;
   }
   
   // Array to track volume nodes
   double volumes[HFT_PRICE_LEVELS];
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      volumes[i] = m_marketProfile.volumeProfile[i];
   }
   
   // Sort volumes to find highest volume levels
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      for(int j = i + 1; j < HFT_PRICE_LEVELS; j++) {
         if(volumes[i] < volumes[j]) {
            // Swap volumes
            double tempVol = volumes[i];
            volumes[i] = volumes[j];
            volumes[j] = tempVol;
         }
      }
   }
   
   // Threshold for significant volume (top 20% of volumes)
   double volumeThreshold = volumes[MathMin(HFT_PRICE_LEVELS / 5, HFT_PRICE_LEVELS - 1)];
   
   // Current tick price for reference
   double currentPrice = (m_tickBuffer[m_tickBufferIndex].bid + m_tickBuffer[m_tickBufferIndex].ask) / 2.0;
   
   int resistanceCount = 0;
   int supportCount = 0;
   
   // Identify support and resistance levels based on volume profile
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      if(m_marketProfile.volumeProfile[i] >= volumeThreshold) {
         double levelPrice = m_marketProfile.priceLevels[i].price;
         
         // Determine if this is support or resistance based on current price
         if(levelPrice < currentPrice) {
            // Support level
            if(supportCount < 10) {
               m_marketProfile.supportLevels[supportCount] = levelPrice;
               m_marketProfile.priceLevels[i].isSupport = true;
               supportCount++;
            }
         } else {
            // Resistance level
            if(resistanceCount < 10) {
               m_marketProfile.resistanceLevels[resistanceCount] = levelPrice;
               m_marketProfile.priceLevels[i].isResistance = true;
               resistanceCount++;
            }
         }
      }
   }
   
   // Sort support levels in descending order (highest first)
   for(int i = 0; i < supportCount; i++) {
      for(int j = i + 1; j < supportCount; j++) {
         if(m_marketProfile.supportLevels[i] < m_marketProfile.supportLevels[j]) {
            double temp = m_marketProfile.supportLevels[i];
            m_marketProfile.supportLevels[i] = m_marketProfile.supportLevels[j];
            m_marketProfile.supportLevels[j] = temp;
         }
      }
   }
   
   // Sort resistance levels in ascending order (lowest first)
   for(int i = 0; i < resistanceCount; i++) {
      for(int j = i + 1; j < resistanceCount; j++) {
         if(m_marketProfile.resistanceLevels[i] > m_marketProfile.resistanceLevels[j]) {
            double temp = m_marketProfile.resistanceLevels[i];
            m_marketProfile.resistanceLevels[i] = m_marketProfile.resistanceLevels[j];
            m_marketProfile.resistanceLevels[j] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect liquidity clusters                                        |
//+------------------------------------------------------------------+
bool CHFTEngine::DetectLiquidityClusters() {
   // Reset existing liquidity clusters
   for(int i = 0; i < 10; i++) {
      m_marketProfile.liquidityClusterLevels[i] = 0;
   }
   
   // Flag to indicate if clusters were found
   bool clustersFound = false;
   
   // Calculate average volume per level
   double totalVolume = 0;
   int levelCount = 0;
   
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      if(m_marketProfile.volumeProfile[i] > 0) {
         totalVolume += m_marketProfile.volumeProfile[i];
         levelCount++;
      }
   }
   
   if(levelCount == 0) return false;
   
   double avgVolume = totalVolume / levelCount;
   
   // Find clusters (levels with volume >= HFT_CLUSTER_DENSITY * average)
   int clusterCount = 0;
   
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      if(m_marketProfile.volumeProfile[i] >= avgVolume * HFT_CLUSTER_DENSITY) {
         // This is a liquidity cluster
         m_marketProfile.priceLevels[i].isLiquidityCluster = true;
         
         if(clusterCount < 10) {
            m_marketProfile.liquidityClusterLevels[clusterCount] = m_marketProfile.priceLevels[i].price;
            clusterCount++;
            clustersFound = true;
         }
      }
   }
   
   // Calculate overall liquidity score at current price level
   double currentPrice = (m_tickBuffer[m_tickBufferIndex].bid + m_tickBuffer[m_tickBufferIndex].ask) / 2.0;
   
   // Find closest price level to current price
   int closestLevel = 0;
   double minDistance = DBL_MAX;
   
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      double distance = MathAbs(m_marketProfile.priceLevels[i].price - currentPrice);
      if(distance < minDistance) {
         minDistance = distance;
         closestLevel = i;
      }
   }
   
   // Calculate liquidity score (0-100)
   if(m_marketProfile.volumeProfile[closestLevel] > 0) {
      double relativeLiquidity = m_marketProfile.volumeProfile[closestLevel] / avgVolume;
      m_liquidityScore = MathMin(100.0, relativeLiquidity * 50.0);
   } else {
      m_liquidityScore = 0.0;
   }
   
   return clustersFound;
}

//+------------------------------------------------------------------+
//| Update footprint chart (order flow chart)                        |
//+------------------------------------------------------------------+
void CHFTEngine::UpdateFootprintChart() {
   // Clear existing footprint map
   ArrayInitialize(m_footprintMap, 0);
   
   // Current price for reference
   double currentPrice = (m_tickBuffer[m_tickBufferIndex].bid + m_tickBuffer[m_tickBufferIndex].ask) / 2.0;
   
   // Calculate price range for footprint
   double priceRange = m_marketProfile.valueAreaHigh - m_marketProfile.valueAreaLow;
   double footprintHigh = currentPrice + priceRange * 0.2;
   double footprintLow = currentPrice - priceRange * 0.2;
   
   double priceStep = (footprintHigh - footprintLow) / (HFT_PRICE_LEVELS - 1);
   
   // Initialize footprint data
   for(int i = 0; i < HFT_PRICE_LEVELS; i++) {
      for(int j = 0; j < HFT_FOOTPRINT_LEVELS; j++) {
         m_footprintMap[i * HFT_FOOTPRINT_LEVELS + j] = 0;
      }
   }
   
   // Process tick data to build footprint
   int ticksProcessed = 0;
   
   for(int i = 0; i < m_tickBufferSize && ticksProcessed < 200; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      ticksProcessed++;
      
      double midPrice = (m_tickBuffer[idx].bid + m_tickBuffer[idx].ask) / 2.0;
      
      // Skip if outside footprint range
      if(midPrice < footprintLow || midPrice > footprintHigh) continue;
      
      // Calculate price level index
      int priceLevel = (int)MathRound((midPrice - footprintLow) / priceStep);
      if(priceLevel < 0) priceLevel = 0;
      if(priceLevel >= HFT_PRICE_LEVELS) priceLevel = HFT_PRICE_LEVELS - 1;
      
      // Calculate time/step index
      int timeLevel = (int)(i * HFT_FOOTPRINT_LEVELS / 200);
      
      // Update footprint map
      int mapIndex = priceLevel * HFT_FOOTPRINT_LEVELS + timeLevel;
      
      // Add volume to footprint
      m_footprintMap[mapIndex] += m_tickBuffer[idx].volume;
      
      // Color by delta (positive = buying, negative = selling)
      if(m_tickBuffer[idx].delta > 0) {
         // Add to buy volume
      } else if(m_tickBuffer[idx].delta < 0) {
         // Add to sell volume (stored as negative)
         m_footprintMap[mapIndex] = -m_footprintMap[mapIndex];
      }
   }
   
   // Calculate footprint imbalance (ratio of buy to sell volume)
   double totalBuyVolume = 0, totalSellVolume = 0;
   
   for(int i = 0; i < HFT_PRICE_LEVELS * HFT_FOOTPRINT_LEVELS; i++) {
      if(m_footprintMap[i] > 0) {
         totalBuyVolume += m_footprintMap[i];
      } else {
         totalSellVolume += MathAbs(m_footprintMap[i]);
      }
   }
   
   // Calculate imbalance
   if(totalSellVolume > 0) {
      m_footprintImbalance = totalBuyVolume / totalSellVolume;
   } else if(totalBuyVolume > 0) {
      m_footprintImbalance = 999.0; // Extremely bullish
   } else {
      m_footprintImbalance = 1.0; // Neutral
   }
}

//+------------------------------------------------------------------+
//| Calculate order flow metrics                                     |
//+------------------------------------------------------------------+
void CHFTEngine::CalculateOrderFlowMetrics() {
   // This function calculates various order flow metrics
   
   // Calculate average spread
   double totalSpread = 0;
   int spreadCount = 0;
   
   for(int i = 0; i < 50; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      totalSpread += m_tickBuffer[idx].spread;
      spreadCount++;
   }
   
   if(spreadCount > 0) {
      m_orderContext.spreadEMA = totalSpread / spreadCount;
   }
   
   // Calculate volume EMA
   double totalVolume = 0;
   int volumeCount = 0;
   
   for(int i = 0; i < 50; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      totalVolume += m_tickBuffer[idx].volume;
      volumeCount++;
   }
   
   if(volumeCount > 0) {
      m_orderContext.volumeEMA = totalVolume / volumeCount;
   
      // Calculate volume standard deviation
      double sumSquaredDiff = 0;
      
      for(int i = 0; i < 50; i++) {
         int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
         if(m_tickBuffer[idx].time == 0) continue;
         
         double diff = m_tickBuffer[idx].volume - m_orderContext.volumeEMA;
         sumSquaredDiff += diff * diff;
      }
      
      m_orderContext.volumeStdDev = MathSqrt(sumSquaredDiff / volumeCount);
      
      // Set abnormal volume threshold
      m_orderContext.abnormalVolumeThreshold = m_orderContext.volumeEMA + 2 * m_orderContext.volumeStdDev;
   }
   
   // Calculate price standard deviation
   double sumPrices = 0;
   double sumSquaredPriceDiff = 0;
   int priceCount = 0;
   
   for(int i = 0; i < 50; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      double midPrice = (m_tickBuffer[idx].bid + m_tickBuffer[idx].ask) / 2.0;
      sumPrices += midPrice;
      priceCount++;
   }
   
   if(priceCount > 0) {
      double avgPrice = sumPrices / priceCount;
      
      for(int i = 0; i < 50; i++) {
         int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
         if(m_tickBuffer[idx].time == 0) continue;
         
         double midPrice = (m_tickBuffer[idx].bid + m_tickBuffer[idx].ask) / 2.0;
         double diff = midPrice - avgPrice;
         sumSquaredPriceDiff += diff * diff;
      }
      
      m_orderContext.priceStdDev = MathSqrt(sumSquaredPriceDiff / priceCount);
   }
   
   // Calculate buy/sell pressure (from cumulative delta)
   double cumulativeDelta = m_cumulativeDelta[m_tickBufferIndex];
   
   // Normalize to get a pressure indicator between -1 and 1
   double maxDelta = 1000; // Arbitrary scaling factor
   m_orderContext.buyPressure = MathMax(0, MathMin(1, cumulativeDelta / maxDelta));
   m_orderContext.sellPressure = MathMax(0, MathMin(1, -cumulativeDelta / maxDelta));
   
   // Calculate trade aggressiveness
   double agressiveCount = 0;
   int totalCount = 0;
   
   for(int i = 0; i < 20; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      if(m_tickBuffer[idx].time == 0) continue;
      
      totalCount++;
      
      // Trades with above-average volume and clear direction are considered aggressive
      if(m_tickBuffer[idx].volume > m_orderContext.volumeEMA &&
         MathAbs(m_tickBuffer[idx].delta) > 0) {
         agressiveCount++;
      }
   }
   
   if(totalCount > 0) {
      m_orderContext.tradeAggressiveness = agressiveCount / totalCount;
   }
   
   // Calculate overall order flow imbalance
   m_orderFlowImbalance = m_footprintImbalance;
}

//+------------------------------------------------------------------+
//| Calculate volume absorption                                      |
//+------------------------------------------------------------------+
void CHFTEngine::CalculateVolumeAbsorption() {
   // This function calculates buy/sell absorption ratios
   
   // Absorption occurs when large volume doesn't move price much
   // Calculate for both buying and selling pressure
   
   // Buying absorption (large buying volume that doesn't move price up)
   double buyVolume = 0;
   double priceChange = 0;
   double buyAcceleration = 0;
   
   for(int i = 0; i < 20; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      int prevIdx = (idx - 1 + m_tickBufferSize) % m_tickBufferSize;
      
      if(m_tickBuffer[idx].time == 0 || m_tickBuffer[prevIdx].time == 0) continue;
      
      // Look for buy volume
      if(m_tickBuffer[idx].delta > 0) {
         buyVolume += m_tickBuffer[idx].buyVolume;
         
         // Calculate price change
         double prevPrice = (m_tickBuffer[prevIdx].bid + m_tickBuffer[prevIdx].ask) / 2.0;
         double currPrice = (m_tickBuffer[idx].bid + m_tickBuffer[idx].ask) / 2.0;
         
         // Positive change means price moved up
         double change = (currPrice - prevPrice) / SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         priceChange += change;
         
         // Efficiency: how much price moved relative to volume
         if(m_tickBuffer[idx].buyVolume > 0) {
            buyAcceleration += change / m_tickBuffer[idx].buyVolume;
         }
      }
   }
   
   // Calculate buyer absorption ratio
   if(buyVolume > 0 && priceChange > 0) {
      // High absorption = low price change relative to volume
      m_buyerAbsorption = buyVolume / priceChange;
   } else {
      m_buyerAbsorption = 0;
   }
   
   // Selling absorption (large selling volume that doesn't move price down)
   double sellVolume = 0;
   priceChange = 0;
   double sellAcceleration = 0;
   
   for(int i = 0; i < 20; i++) {
      int idx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      int prevIdx = (idx - 1 + m_tickBufferSize) % m_tickBufferSize;
      
      if(m_tickBuffer[idx].time == 0 || m_tickBuffer[prevIdx].time == 0) continue;
      
      // Look for sell volume
      if(m_tickBuffer[idx].delta < 0) {
         sellVolume += m_tickBuffer[idx].sellVolume;
         
         // Calculate price change
         double prevPrice = (m_tickBuffer[prevIdx].bid + m_tickBuffer[prevIdx].ask) / 2.0;
         double currPrice = (m_tickBuffer[idx].bid + m_tickBuffer[idx].ask) / 2.0;
         
         // Negative change means price moved down
         double change = (currPrice - prevPrice) / SymbolInfoDouble(m_symbol, SYMBOL_POINT);
         priceChange += change;
         
         // Efficiency: how much price moved relative to volume
         if(m_tickBuffer[idx].sellVolume > 0) {
            sellAcceleration += change / m_tickBuffer[idx].sellVolume;
         }
      }
   }
   
   // Calculate seller absorption ratio
   if(sellVolume > 0 && priceChange < 0) {
      // High absorption = low price change relative to volume
      m_sellerAbsorption = sellVolume / MathAbs(priceChange);
   } else {
      m_sellerAbsorption = 0;
   }
   
   // Calculate volumetric velocity (how efficiently volume moves price)
   m_volumetricVelocity = (buyAcceleration - sellAcceleration);
   
   // Calculate effort vs result ratio
   double totalVolume = buyVolume + sellVolume;
   double netPriceChange = m_tickBuffer[m_tickBufferIndex].bid - 
                           m_tickBuffer[(m_tickBufferIndex - 20 + m_tickBufferSize) % m_tickBufferSize].bid;
                           
   if(totalVolume > 0 && netPriceChange != 0) {
      m_effortVsResult = totalVolume / MathAbs(netPriceChange);
   } else {
      m_effortVsResult = 100; // High effort, no result
   }
   
   // Update market profile absorption metrics
   m_marketProfile.absorbedVolume = MathMax(m_buyerAbsorption, m_sellerAbsorption);
}

//+------------------------------------------------------------------+
//| Compute market efficiency ratio                                  |
//+------------------------------------------------------------------+
void CHFTEngine::ComputeEfficiencyRatio() {
   // Market efficiency ratio measures how efficiently price moves
   // 1.0 = perfectly efficient trend, 0.0 = completely random
   
   double startPrice = m_tickBuffer[(m_tickBufferIndex - 100 + m_tickBufferSize) % m_tickBufferSize].bid;
   double endPrice = m_tickBuffer[m_tickBufferIndex].bid;
   
   // Net price change
   double netChange = MathAbs(endPrice - startPrice);
   
   // Path length (sum of all price movements)
   double pathLength = 0;
   
   for(int i = 1; i < 100; i++) {
      int currIdx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      int prevIdx = (m_tickBufferIndex - i - 1 + m_tickBufferSize) % m_tickBufferSize;
      
      if(m_tickBuffer[currIdx].time == 0 || m_tickBuffer[prevIdx].time == 0) continue;
      
      double currPrice = m_tickBuffer[currIdx].bid;
      double prevPrice = m_tickBuffer[prevIdx].bid;
      
      pathLength += MathAbs(currPrice - prevPrice);
   }
   
   // Calculate efficiency ratio
   if(pathLength > 0) {
      m_marketProfile.efficiency = netChange / pathLength;
   } else {
      m_marketProfile.efficiency = 0;
   }
}

//+------------------------------------------------------------------+
//| Compute market entropy (randomness)                              |
//+------------------------------------------------------------------+
double CHFTEngine::ComputeMarketEntropy() {
   // Market entropy measures randomness in price movements
   // Higher values indicate more random price movement
   
   // Construct a histogram of price changes
   double changes[10] = {0};
   int counts[10] = {0};
   int totalCount = 0;
   
   // Get range of price changes
   double minChange = 0, maxChange = 0;
   
   for(int i = 1; i < 100; i++) {
      int currIdx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      int prevIdx = (m_tickBufferIndex - i - 1 + m_tickBufferSize) % m_tickBufferSize;
      
      if(m_tickBuffer[currIdx].time == 0 || m_tickBuffer[prevIdx].time == 0) continue;
      
      double currPrice = (m_tickBuffer[currIdx].bid + m_tickBuffer[currIdx].ask) / 2.0;
      double prevPrice = (m_tickBuffer[prevIdx].bid + m_tickBuffer[prevIdx].ask) / 2.0;
      
      double change = currPrice - prevPrice;
      
      if(change < minChange) minChange = change;
      if(change > maxChange) maxChange = change;
   }
   
   // Skip if no range
   if(maxChange <= minChange) return 0.5;
   
   // Bin size
   double binSize = (maxChange - minChange) / 10;
   
   // Count price changes in each bin
   for(int i = 1; i < 100; i++) {
      int currIdx = (m_tickBufferIndex - i + m_tickBufferSize) % m_tickBufferSize;
      int prevIdx = (m_tickBufferIndex - i - 1 + m_tickBufferSize) % m_tickBufferSize;
      
      if(m_tickBuffer[currIdx].time == 0 || m_tickBuffer[prevIdx].time == 0) continue;
      
      double currPrice = (m_tickBuffer[currIdx].bid + m_tickBuffer[currIdx].ask) / 2.0;
      double prevPrice = (m_tickBuffer[prevIdx].bid + m_tickBuffer[prevIdx].ask) / 2.0;
      
      double change = currPrice - prevPrice;
      
      // Determine bin
      int bin = (int)((change - minChange) / binSize);
      if(bin < 0) bin = 0;
      if(bin >= 10) bin = 9;
      
      counts[bin]++;
      totalCount++;
   }
   
   // Skip if no data
   if(totalCount == 0) return 0.5;
   
   // Calculate entropy
   double entropy = 0;
   
   for(int i = 0; i < 10; i++) {
      if(counts[i] > 0) {
         double p = (double)counts[i] / totalCount;
         entropy -= p * MathLog(p);
      }
   }
   
   // Normalize to 0-1 range (max entropy for 10 bins = ln(10))
   entropy /= MathLog(10);
   
   return entropy;
}

//+------------------------------------------------------------------+
//| Detect market maker activity                                     |
//+------------------------------------------------------------------+
void CHFTEngine::DetectMarketMakerActivity() {
   // This function detects patterns that suggest market maker activity
   
   // Key signs of market maker activity:
   // 1. Large hidden liquidity (price absorption)
   // 2. Rapid quote refreshes
   // 3. Precise reversals at key levels
   // 4. Stop hunting patterns
   
   // Check for large hidden liquidity
   bool hiddenLiquidity = m_buyerAbsorption > 10.0 || m_sellerAbsorption > 10.0;
   
   // Check for precise reversals at key levels
   bool preciseReversal = false;
   double currentPrice = (m_tickBuffer[m_tickBufferIndex].bid + m_tickBuffer[m_tickBufferIndex].ask) / 2.0;
   
   // Look for recent reversal at support/resistance level
   double minDistance = DBL_MAX;
   
   // Check support levels
   for(int i = 0; i < 10; i++) {
      if(m_marketProfile.supportLevels[i] <= 0) continue;
      
      double dist = MathAbs(m_marketProfile.supportLevels[i] - currentPrice);
      if(dist < minDistance) {
         minDistance = dist;
      }
   }
   
   // Check resistance levels
   for(int i = 0; i < 10; i++) {
      if(m_marketProfile.resistanceLevels[i] <= 0) continue;
      
      double dist = MathAbs(m_marketProfile.resistanceLevels[i] - currentPrice);
      if(dist < minDistance) {
         minDistance = dist;
      }
   }
   
   // If very close to a key level
   double pointSize = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   if(minDistance < 10 * pointSize && m_priceAcceleration * m_regressionSlope < 0) {
      // Price acceleration in opposite direction of trend at key level
      preciseReversal = true;
   }
   
   // Check for stop hunting patterns
   bool stopHunting = false;
   
   // Rapid price movements beyond key levels followed by reversals
   if(m_volatilityRatio > 2.0 && preciseReversal) {
      stopHunting = true;
   }
   
   // Update market maker activity flag
   bool marketMakerActive = hiddenLiquidity || preciseReversal || stopHunting;
   
   if(marketMakerActive) {
      m_logger.Debug("HFT Engine detected potential market maker activity");
   }
}

//+------------------------------------------------------------------+
//| Detect liquidity sweeps (stop hunts)                             |
//+------------------------------------------------------------------+
void CHFTEngine::DetectLiquiditySweeps() {
   // This function detects liquidity sweeps (stop hunts)
   
   // Liquidity sweeps are characterized by:
   // 1. Quick price movement beyond a key level
   // 2. Immediate reversal after sweeping the level
   // 3. Large volume at the extreme
   
   // Check for recent high volatility
   if(m_volatilityRatio < 1.5) return;
   
   // Current price for reference
   double currentPrice = (m_tickBuffer[m_tickBufferIndex].bid + m_tickBuffer[m_tickBufferIndex].ask) / 2.0;
   
   // Check for sweep up (bear trap)
   bool sweepUp = false;
   
   for(int i = 0; i < 10; i++) {
      if(m_marketProfile.resistanceLevels[i] <= 0) continue;
      
      double resistanceLevel = m_marketProfile.resistanceLevels[i];
      
      // Check if we've recently broken above resistance
      bool brokeAbove = false;
      bool reversedDown = false;
      int brokeAtIdx = 0;
      
      for(int j = 1; j < 20; j++) {
         int idx = (m_tickBufferIndex - j + m_tickBufferSize) % m_tickBufferSize;
         if(m_tickBuffer[idx].time == 0) continue;
         
         double highPrice = m_tickBuffer[idx].ask;
         
         if(!brokeAbove && highPrice > resistanceLevel) {
            brokeAbove = true;
            brokeAtIdx = j;
         } else if(brokeAbove && highPrice < resistanceLevel && j > brokeAtIdx) {
            reversedDown = true;
            break;
         }
      }
      
      // If broke above resistance and reversed, it's a potential sweep
      if(brokeAbove && reversedDown) {
         sweepUp = true;
         m_logger.Debug("HFT Engine detected potential
