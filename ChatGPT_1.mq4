// Define input parameters
input int TradingStartTime = 800; // Trading start time in server time (8:00 AM)
input int TradingEndTime = 1400; // Trading end time in server time (2:00 PM)
input double RiskPercentage = 1.0; // Risk percentage per trade

// Declare global variables for order tickets
int buyOrderTicket = 0;
int sellOrderTicket = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Get the current server time
   datetime currentTime = TimeCurrent();
   int currentHour = TimeHour(currentTime);
   int currentMinute = TimeMinute(currentTime);

   // Check if it's within trading hours
   if (currentHour >= TradingStartTime/100 && currentHour < TradingEndTime/100)
   {
      // Calculate lot size based on risk percentage and account balance
      double lotSize = AccountBalance() * RiskPercentage / 100.0 / MarketInfo(Symbol(), MODE_MARGINREQUIRED);

      // Calculate stop loss and take profit levels
      double stopLoss = 0;
      double takeProfit = 0;

      // Check entry conditions for buy trade
      if (BuyConditionsMet())
      {
         // Calculate stop loss and take profit levels
         stopLoss = Low[0]; // Lowest price of the entry candle
         takeProfit = stopLoss + (stopLoss - Low[0]) * 2; // 2 times the stop loss

         // Place buy order at market price
         buyOrderTicket = OrderSend(Symbol(), OP_BUY, lotSize, MarketInfo(Symbol(), MODE_ASK), 2, stopLoss, takeProfit, "Buy Order", 0, clrNONE);
         if (buyOrderTicket > 0)
         {
            Print("Buy order placed successfully");
         }
         else
         {
            Print("Error placing buy order. Error code:", GetLastError());
         }
      }

      // Check entry conditions for sell trade
      if (SellConditionsMet())
      {
         // Calculate stop loss and take profit levels
         stopLoss = High[0]; // Highest price of the entry candle
         takeProfit = stopLoss - (High[0] - stopLoss) * 2; // 2 times the stop loss

         // Place sell order at market price
         sellOrderTicket = OrderSend(Symbol(), OP_SELL, lotSize, MarketInfo(Symbol(), MODE_BID), 2, stopLoss, takeProfit, "Sell Order", 0, clrNONE);
         if (sellOrderTicket > 0)
         {
            Print("Sell order placed successfully");
         }
         else
         {
            Print("Error placing sell order. Error code:", GetLastError());
         }
      }
   }
}

// Define functions to check entry conditions
bool BuyConditionsMet()
{
   // Ichimoku Cloud Conditions
   bool isAboveKumo = iIchimoku(Symbol(), 0, 9, 26, 52, 0, 1) > iLow(Symbol(), 0, 1);
   bool isTenkanAboveKijun = iIchimoku(Symbol(), 0, 9, 26, 52, 1, 1) > iIchimoku(Symbol(), 0, 9, 26, 52, 2, 1);
   bool isChikouAbovePrice = iIchimoku(Symbol(), 0, 9, 26, 52, 3, 1) > Close[1];

   // RSI Conditions
   bool isRSICrossAbove30 = iRSI(Symbol(), 0, 14, PRICE_CLOSE, 1) < 30 && iRSI(Symbol(), 0, 14, PRICE_CLOSE, 0) >= 30;

   // Volume Conditions
   bool isVolumeAboveAverage = Volume[1] > iMA(Symbol(), 0, 10, 0, MODE_SMA, PRICE_CLOSE, 0);

   // Check if all conditions are met for buy trade
   return isAboveKumo && isTenkanAboveKijun && isChikouAbovePrice && isRSICrossAbove30 && isVolumeAboveAverage;
}

bool SellConditionsMet()
{
   // Ichimoku Cloud Conditions
   bool isBelowKumo = iIchimoku(Symbol(), 0, 9, 26, 52, 0, 1) < iHigh(Symbol(), 0, 1);
   bool isTenkanBelowKijun = iIchimoku(Symbol(), 0, 9, 26, 52, 1, 1) < iIchimoku(Symbol(), 0, 9, 26, 52, 2, 1);
   bool isChikouBelowPrice = iIchimoku(Symbol(), 0, 9, 26, 52, 3, 1) < Close[1];

   // RSI Conditions
   bool isRSICrossBelow70 = iRSI(Symbol(), 0, 14, PRICE_CLOSE, 1) > 70 && iRSI(Symbol(), 0, 14, PRICE_CLOSE, 0) <= 70;

   // Volume Conditions
   bool isVolumeBelowAverage = Volume[1] < iMA(Symbol(), 0, 10, 0, MODE_SMA, PRICE_CLOSE, 0);

   // Check if all conditions are met for sell trade
   return isBelowKumo && isTenkanBelowKijun && isChikouBelowPrice && isRSICrossBelow70 && isVolumeBelowAverage;
}
