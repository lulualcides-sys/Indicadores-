// Nexus Indicator Tester EA v1.00 - tester ONLY
// Reads CONFIRMED BUY/SELL from buffers 0 and 1 of six MT5 indicators.
// Does not trade in a live or demo terminal, only Strategy Tester.
#property strict
#property version "1.00"
#property tester_indicator "NexusBacktest\\H1_Vector_Factor_M1.ex5"
#property tester_indicator "NexusBacktest\\Nexus_Liquidity_Sweep_NR.ex5"
#property tester_indicator "NexusBacktest\\Nexus_FVG_Retest_NR.ex5"
#property tester_indicator "NexusBacktest\\Nexus_Session_VWAP_NR.ex5"
#property tester_indicator "NexusBacktest\\Nexus_Structure_Break_NR.ex5"
#property tester_indicator "NexusBacktest\\Nexus_Clean_Signals_NR.ex5"
#include <Trade\Trade.mqh>

enum ENUM_NEXUS_TEST { TEST_H1=0,TEST_SWEEP=1,TEST_FVG=2,TEST_VWAP=3,TEST_STRUCTURE=4,TEST_CLEAN=5 };
enum ENUM_CLEAN_MODE { CLEAN_AUTO=0,CLEAN_BREAKOUT=1,CLEAN_SWEEP=2 };
input ENUM_NEXUS_TEST InpIndicator=TEST_CLEAN;
input ENUM_CLEAN_MODE InpCleanMode=CLEAN_AUTO;
input double InpLots=0.01;
input double InpTakeProfitR=1.0;
input double InpStopBufferATR=0.08;
input int InpATRPeriod=14;
input int InpTimeExitBars=12;
input int InpMaxSpreadPoints=0;
input int InpSlippagePoints=20;
input long InpMagic=6112026;
input bool InpPrintEntries=true;

CTrade trade;
int handle=INVALID_HANDLE,atrHandle=INVALID_HANDLE;
datetime lastBar=0;
int signalCount=0;

int SignalIndicator()
  {
   switch(InpIndicator)
     {
      case TEST_H1: return iCustom(_Symbol,_Period,"NexusBacktest\\H1_Vector_Factor_M1");
      case TEST_SWEEP: return iCustom(_Symbol,_Period,"NexusBacktest\\Nexus_Liquidity_Sweep_NR");
      case TEST_FVG: return iCustom(_Symbol,_Period,"NexusBacktest\\Nexus_FVG_Retest_NR");
      case TEST_VWAP: return iCustom(_Symbol,_Period,"NexusBacktest\\Nexus_Session_VWAP_NR");
      case TEST_STRUCTURE: return iCustom(_Symbol,_Period,"NexusBacktest\\Nexus_Structure_Break_NR");
      case TEST_CLEAN: return iCustom(_Symbol,_Period,"NexusBacktest\\Nexus_Clean_Signals_NR",InpCleanMode);
     }
   return INVALID_HANDLE;
  }

int OnInit()
  {
   // Safety: tester only, no real or demo trading.
   if(!MQLInfoInteger(MQL_TESTER))
     {
      Print("This EA can only run in Strategy Tester.");
      return INIT_FAILED;
     }
   if(InpIndicator==TEST_H1 && _Period!=PERIOD_M1)
     {
      Print("H1 Vector Factor v1.30 only supports M1.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpLots<=0 || InpTakeProfitR<=0 || InpStopBufferATR<0 ||
      InpATRPeriod<2 || InpTimeExitBars<1 || InpMaxSpreadPoints<0)
      return INIT_PARAMETERS_INCORRECT;
   handle=SignalIndicator();
   if(handle==INVALID_HANDLE)
     {
      Print("Indicator not compiled or absent. Error ",GetLastError());
      return INIT_FAILED;
     }
   atrHandle=iATR(_Symbol,_Period,InpATRPeriod);
   if(atrHandle==INVALID_HANDLE) return INIT_FAILED;
   trade.SetExpertMagicNumber((ulong)InpMagic);
   trade.SetDeviationInPoints(InpSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   lastBar=iTime(_Symbol,_Period,0);
   Print("Nexus tester ready. Indicator id ",(int)InpIndicator,"; timeframe ",EnumToString(_Period));
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(handle!=INVALID_HANDLE) IndicatorRelease(handle);
   if(atrHandle!=INVALID_HANDLE) IndicatorRelease(atrHandle);
   Print("Nexus indicator tester: signal trades requested ",signalCount);
  }

bool LastClosedSignal(bool &buy,bool &sell)
  {
   buy=false;sell=false;
   double a[1],b[1];
   if(CopyBuffer(handle,0,1,1,a)!=1 || CopyBuffer(handle,1,1,1,b)!=1)
      return false;
   // shift 1: completed bar, never forming bar 0
   buy=MathIsValidNumber(a[0]) && a[0]!=EMPTY_VALUE && a[0]>0.0 && a[0]<DBL_MAX/2.0;
   sell=MathIsValidNumber(b[0]) && b[0]!=EMPTY_VALUE && b[0]>0.0 && b[0]<DBL_MAX/2.0;
   return true;
  }

double LotsForBroker()
  {
   double minv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0 || InpLots<minv) return 0.0;
   return NormalizeDouble(MathMin(maxv,MathFloor(InpLots/step+1e-8)*step),8);
  }

void CloseExpiredPosition()
  {
   if(!PositionSelect(_Symbol)) return;
   if(PositionGetInteger(POSITION_MAGIC)!=InpMagic) return;
   datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
   int barsElapsed=iBarShift(_Symbol,_Period,opened,false);
   if(barsElapsed>=InpTimeExitBars && barsElapsed>=0)
     {
      if(!trade.PositionClose(_Symbol))
         Print("Time exit failed: ",trade.ResultRetcodeDescription());
     }
  }

void OnTick()
  {
   datetime bar=iTime(_Symbol,_Period,0);
   if(bar==0 || bar==lastBar) return;
   lastBar=bar;
   CloseExpiredPosition();
   if(Bars(_Symbol,_Period)<100 || PositionSelect(_Symbol)) return;
   bool buy=false,sell=false;
   if(!LastClosedSignal(buy,sell) || buy==sell) return;
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0 || tick.bid<=0) return;
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(point<=0) return;
   if(InpMaxSpreadPoints>0 && (tick.ask-tick.bid)/point>InpMaxSpreadPoints) return;
   double a[1];
   if(CopyBuffer(atrHandle,0,1,1,a)!=1 || a[0]<=0) return;
   double low=iLow(_Symbol,_Period,1),high=iHigh(_Symbol,_Period,1);
   if(high<=low) return;
   double entry=(buy?tick.ask:tick.bid);
   double stop=(buy?low-InpStopBufferATR*a[0]:high+InpStopBufferATR*a[0]);
   double minStop=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*point+2*point;
   if(buy)stop=MathMin(stop,tick.bid-minStop);
   else stop=MathMax(stop,tick.ask+minStop);
   double risk=(buy?entry-stop:stop-entry);
   if(risk<=point) return;
   double target=(buy?entry+InpTakeProfitR*risk:entry-InpTakeProfitR*risk);
   int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   stop=NormalizeDouble(stop,digits);
   target=NormalizeDouble(target,digits);
   double lots=LotsForBroker();
   if(lots<=0) { Print("Lots below broker minimum");return; }
   if(InpPrintEntries)
      Print("CLOSED SIGNAL ",(buy?"BUY":"SELL")," at ",TimeToString(bar),
            " stop ",DoubleToString(stop,digits),
            " target ",DoubleToString(target,digits));
   bool ok=(buy?trade.Buy(lots,_Symbol,0,stop,target,"Nexus signal test"):
                trade.Sell(lots,_Symbol,0,stop,target,"Nexus signal test"));
   if(ok && (trade.ResultRetcode()==TRADE_RETCODE_DONE || trade.ResultRetcode()==TRADE_RETCODE_PLACED))
      signalCount++;
   else Print("Order rejected: ",trade.ResultRetcodeDescription());
  }
