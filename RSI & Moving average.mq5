
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
static input long    InpMagicNumber    = 546721;   // magic number
static input double  InputLotSize      = 0.01;     // lot size
input  int           InputRSIPeriod    =  21;      //rso period
input  int           InputRSILevel     = 70;       // rsi level (upper)
input  int           InputStopLoss     = 200;      // stop loss in points (0=off)
input  int           InputTakeProfit   = 100;
input  bool          InputCloseSignal  = false;    //close trade by opposite signal


//Input for moving average
input  int           InpFastPeriod     = 14;
input  int           InpSlowPeriod     = 21;
//Inputs for Alligator 
//input  int           AlligatorJawPeriod = 13;
//input  int           AlligatorTeethPeriod = 8;
//input  int           AlligatorLipsPeriod = 5;

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade\trade.mqh>

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

int handle;
double buffer[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy = 0;
datetime openTimeSell = 0;

int fastHandle;
int slowHandle;
double fastBuffer[];
double slowBuffer[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      // check for user's input
   if(InpMagicNumber<=0){
      Alert("Magicnumber <= 0");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InputLotSize<=0 || InputLotSize>10){
      Alert("Lost size <= 0 or > 10");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InputRSIPeriod<=1){
      Alert("RSI period <= 1");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InputRSILevel>=100 || InputRSILevel<=50){
      Alert("RSI level >=100 or RSI level <= 50");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InputStopLoss<0){
      Alert("stop loss < 0");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InputTakeProfit<0){
      Alert("take profit < 0");
      return INIT_PARAMETERS_INCORRECT;
   }
    
    if(InpFastPeriod<0){
      Alert("fastPeriod < 0");
      return INIT_PARAMETERS_INCORRECT;
   }
       
     if(InpSlowPeriod<0){
      Alert("slowPeriod < 0");
      return INIT_PARAMETERS_INCORRECT;
   }
        if(InpSlowPeriod<InpFastPeriod){
      Alert("slowPeriod < fast");
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // set magic number to trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   
   // create rsi handle
   handle = iRSI(_Symbol,PERIOD_CURRENT,InputRSIPeriod,PRICE_CLOSE);
   if(handle == INVALID_HANDLE){
   Alert("Failed to create indicator handle");
   return INIT_FAILED;
   }
   
   
   //Create moving average handle
   fastHandle = iMA(_Symbol,PERIOD_CURRENT,InpFastPeriod,0,MODE_SMA,PRICE_CLOSE);
   if(fastHandle==INVALID_HANDLE){
      Alert("Failed to createa fast handle");
      return INIT_FAILED;
   }
   
   slowHandle = iMA(_Symbol,PERIOD_CURRENT,InpSlowPeriod,0,MODE_SMA,PRICE_CLOSE);
   if(slowHandle==INVALID_HANDLE){
      Alert("Failed to createa slow handle");
      return INIT_FAILED;
   }


   

   // set buffer as series for RSI
   ArraySetAsSeries(buffer,true);
   
    // set buffer as series for MovingAverage
   ArraySetAsSeries(slowBuffer,true);
   ArraySetAsSeries(fastBuffer,true);


   return(INIT_SUCCEEDED);
  }
  
  
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   // realese indicator handle
      //For RSI 
   if(handle!=INVALID_HANDLE){
   IndicatorRelease(handle);
   }


      // Moivng average
   if(fastHandle != INVALID_HANDLE){IndicatorRelease(fastHandle);}
   if(slowHandle != INVALID_HANDLE){IndicatorRelease(slowHandle);}

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
 // iAlligator implantation
       //creating price array
      double jawsArray[];
      double teethArray[];
      double lipsArray[];   
      //Sorting data
      ArraySetAsSeries(jawsArray,true);
      ArraySetAsSeries(teethArray,true);
      ArraySetAsSeries(lipsArray,true);
      //define Alligator

      int alligatorDef=iAlligator(_Symbol,_Period,13,8,8,5,5,3,MODE_SMMA,PRICE_MEDIAN);      
      //define data and store result
      CopyBuffer(alligatorDef,0,0,3,jawsArray);
      CopyBuffer(alligatorDef,1,0,3,teethArray);
      CopyBuffer(alligatorDef,2,0,3,lipsArray);
      //get value of current data
      double jawsValue=NormalizeDouble(jawsArray[0],5);
      double teethValue=NormalizeDouble(teethArray[0],5);
      double lipsValue=NormalizeDouble(lipsArray[0],5);
      bool alligatorBuySignal=false;
      bool alligatorSellSignal=false;
      
      //conditions of Alligator
         if(lipsValue>teethValue && lipsValue>jawsValue)
           {
            alligatorBuySignal=true;
            Comment("Buy","\n",
                    "jawsValue = ",jawsValue,"\n",
                    "teethValue = ",teethValue,"\n",
                    "lipsValue = ",lipsValue);
           }
         if(lipsValue<teethValue && lipsValue<jawsValue)
           {
           alligatorSellSignal=true;
            Comment("Sell","\n",
                    "jawsValue = ",jawsValue,"\n",
                    "teethValue = ",teethValue,"\n",
                    "lipsValue = ",lipsValue);
           }
 
 
 
 
 // get current tick
 if(!SymbolInfoTick(_Symbol,currentTick)){Print("Failed to get current tick"); return;}
 
  // Get moving average
      //Fast
       int valuesMA = CopyBuffer(fastHandle,0,0,2,fastBuffer);
       if(valuesMA != 2){
       Print("Not enogh data for fast moving average");
       return;
       }
       
      //Slow
       valuesMA = CopyBuffer(slowHandle,0,0,2,slowBuffer);
       if(valuesMA != 2){
       Print("Not enogh data for Slow moving average");
       return;
       }
 
       // get rsi values
       int values = CopyBuffer(handle,0,0,2,buffer);
       if(values!=2){
       Print("failed to get indicator values");
       return;
  }

  
  Comment("fast[0]:",fastBuffer[0],
         "\nfast[1]:",fastBuffer[1],
         "\nslow[0]:",slowBuffer[0],
         "\nslow[1]:",slowBuffer[1]);



 
 Comment("buffer[0]:",buffer[0],
         "\nbuffer[1]:",buffer[1]);


// count open positions
int cntBuy, cntSell;
if(!CountOpenPositions(cntBuy,cntSell)){return;}

// Check for movingAverage
bool BuySignalMovingAverage =false;
bool SellSignalMovingAverage =false;

//Buy
if(fastBuffer[1] <= slowBuffer[1] && fastBuffer[0] > slowBuffer[0]){
BuySignalMovingAverage = true;}

//Sell
if(fastBuffer[1] >= slowBuffer[1] && fastBuffer[0] < slowBuffer[0]){
SellSignalMovingAverage = true;}


// Check for buy position

if(BuySignalMovingAverage && cntBuy==0 && buffer[1]>=(100-InputRSILevel) && buffer[0]<(100-InputRSILevel) && openTimeBuy!=iTime(_Symbol,PERIOD_CURRENT,0)){
openTimeBuy = iTime(_Symbol,PERIOD_CURRENT,0);
if(InputCloseSignal){if(!ClosePositions(2)){return;} }
double sl = InputStopLoss==0 ? 0 : currentTick.bid - InputStopLoss*_Point;
double tp = InputTakeProfit==0 ? 0 : currentTick.bid + InputTakeProfit*_Point;
if(!NormalizePrice(sl)){return;}
if(!NormalizePrice(tp)){return;}

trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InputLotSize,currentTick.ask,sl,tp,"RSI EA");

}


// Check for Sell position
if(SellSignalMovingAverage && cntSell==0 && buffer[1]<=InputRSILevel && buffer[0]>InputRSILevel && openTimeSell!=iTime(_Symbol,PERIOD_CURRENT,0)){
openTimeSell = iTime(_Symbol,PERIOD_CURRENT,0);
if(InputCloseSignal){if(!ClosePositions(1)){return;} }
double sl = InputStopLoss==0 ? 0 : currentTick.ask + InputStopLoss*_Point;
double tp = InputTakeProfit==0 ? 0 : currentTick.ask - InputTakeProfit*_Point;
if(!NormalizePrice(sl)){return;}
if(!NormalizePrice(tp)){return;}

trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InputLotSize,currentTick.bid,sl,tp,"RSI EA");

}
 
 
 

  }




//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

// Count open positions

bool CountOpenPositions(int &cntBuy, int &cntSell){
cntBuy = 0;
cntSell =0;
int total = PositionsTotal();

for(int i=total-1; i>=0;i--){
ulong ticket = PositionGetTicket(i);
if(ticket<=0){Print("Failed to get position ticekt"); return false;}
if(!PositionSelectByTicket(ticket)){Print("failed to select position"); return false;}
long magic;
if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}
if(magic==InpMagicNumber){
long type;
if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type"); return false;}
if(type==POSITION_TYPE_BUY){cntBuy++;}
if(type==POSITION_TYPE_SELL){cntSell++;}

}

}

return true;
}



// normalize price

bool NormalizePrice(double &price){

double tickSize=0;
if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){
Print("Failed to get tick size");
return false;
}

price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);

return true;
}



// close positions

bool ClosePositions(int all_buy_sell){

int total = PositionsTotal();

for(int i=total-1; i>=0;i--){
ulong ticket = PositionGetTicket(i);
if(ticket<=0){Print("Failed to get position ticekt"); return false;}
if(!PositionSelectByTicket(ticket)){Print("failed to select position"); return false;}
long magic;
if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position magicnumber"); return false;}
if(magic==InpMagicNumber){
long type;
if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type"); return false;}
if(all_buy_sell==1 && type==POSITION_TYPE_SELL){continue;}
if(all_buy_sell==2 && type==POSITION_TYPE_BUY){continue;}
trade.PositionClose(ticket);
if(trade.ResultRetcode() != TRADE_RETCODE_DONE){
Print("Failed to close position. ticket:",(string)ticket,"result:",(string)trade.ResultRetcode(),
":",trade.CheckResultRetcodeDescription());

}

}

}

return true;
}



