//+------------------------------------------------------------------+
//| Nexus Visual Unificado NR v1.00 — 10 source indicators           |
//| One small entry arrow per directional transition; TP/SL + sound |
//| Virtual trades only. No order execution or future-bar signals.   |
//+------------------------------------------------------------------+
#property copyright "Nexus independent implementation 2026"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots 5
#property indicator_label1 "BUY next-bar entry"
#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrLimeGreen
#property indicator_width1 1
#property indicator_label2 "SELL next-bar entry"
#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrTomato
#property indicator_width2 1
#property indicator_label3 "VWAP (VWAP source only)"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrDodgerBlue
#property indicator_width3 2
#property indicator_label4 "VWAP upper (VWAP source only)"
#property indicator_type4 DRAW_LINE
#property indicator_color4 clrSlateGray
#property indicator_style4 STYLE_DOT
#property indicator_label5 "VWAP lower (VWAP source only)"
#property indicator_type5 DRAW_LINE
#property indicator_color5 clrSlateGray
#property indicator_style5 STYLE_DOT

// Paths compile to: MQL5/Indicators/NexusBase/*.ex5 (see LEIA_PRIMEIRO.md).
#property tester_indicator "NexusBase\\Nexus_Clean_Signals_NR.ex5"
#property tester_indicator "NexusBase\\Nexus_Liquidity_Sweep_NR.ex5"
#property tester_indicator "NexusBase\\Nexus_FVG_Retest_NR.ex5"
#property tester_indicator "NexusBase\\Nexus_Structure_Break_NR.ex5"
#property tester_indicator "NexusBase\\Nexus_Session_VWAP_NR_v1.10.ex5"
#property tester_indicator "NexusBase\\Nexus_Volatility_Squeeze_NR.ex5"
#property tester_indicator "NexusBase\\Nexus_EMA_Trend_Pullback_NR.ex5"
#property tester_indicator "NexusBase\\Nexus_Causal_Kernel_NR.ex5"
#property tester_indicator "NexusBase\\Nexus_Three_Candle_NR.ex5"
#property tester_indicator "NexusBase\\H1_Vector_Factor_M1.ex5"

enum ENUM_NEXUS_MODEL
  {
   NX_CLEAN=0,                // Nexus Clean Signals NR
   NX_LIQUIDITY=1,            // Nexus Liquidity Sweep NR
   NX_FVG=2,                  // Nexus FVG Retest NR
   NX_STRUCTURE=3,            // Nexus Structure Break NR
   NX_VWAP=4,                 // Nexus Session VWAP NR v1.10
   NX_SQUEEZE=5,              // Nexus Volatility Squeeze NR
   NX_EMA=6,                  // Nexus EMA Trend Pullback NR
   NX_KERNEL=7,               // Nexus Causal Kernel NR
   NX_THREE=8,                // Nexus Three Candle NR
   NX_VECTOR_M1=9            // H1 Vector Factor M1 (M1 chart ONLY)
  };

input ENUM_NEXUS_MODEL InpModel          = NX_CLEAN;
input int    InpHistoryBars              = 2500;
input int    InpVisibleResultBars        = 180;
input int    InpATRPeriod               = 14;
input double InpStopBufferATR           = 0.08;
input double InpTP_R                    = 1.50; // One EXIT target; no fake TP counts
input int    InpMaxHoldingBars          = 48;   // Timeout exits at closed bar price
input int    InpMinBarsBetweenSignals   = 8;
input bool   InpOnePerDirection         = true;
input double InpArrowDistanceATR        = 0.90;
input int    InpMaxSpreadPoints         = 0;    // 0 = disabled
input bool   InpShowVWAPLine            = true; // Only for VWAP source
input bool   InpShowResultPoints        = true;
input bool   InpShowExitTags            = true;
input bool   InpShowActiveTP_SL         = true;
input bool   InpShowPanel               = true;
input bool   InpSoundAlert              = true;
input string InpSoundFile               = "alert.wav";
input bool   InpPopupAlert              = false;
input bool   InpPushNotification        = false;

double BuyOut[],SellOut[],VWAPOut[],UpperOut[],LowerOut[];
int g_handle=INVALID_HANDLE;
string g_prefix="";
datetime g_lastProcessedOpen=0, g_lastSoundEntry=0;

struct VirtualTrade
  {
   bool active;
   int dir;
   datetime entryTime;
   int entryIndex;
   double entry,stop,tp,atr;
   int barsHeld;
  };

string ModelName()
  {
   switch(InpModel)
     {
      case NX_CLEAN: return "Clean Signals";
      case NX_LIQUIDITY: return "Liquidity Sweep";
      case NX_FVG: return "FVG Retest";
      case NX_STRUCTURE: return "Structure Break";
      case NX_VWAP: return "Session VWAP";
      case NX_SQUEEZE: return "Volatility Squeeze";
      case NX_EMA: return "EMA Pullback";
      case NX_KERNEL: return "Causal Kernel";
      case NX_THREE: return "Three Candle";
      case NX_VECTOR_M1: return "Vector Factor M1";
     }
   return "Unknown";
  }

string ModelFile()
  {
   switch(InpModel)
     {
      case NX_CLEAN:     return "NexusBase\\Nexus_Clean_Signals_NR";
      case NX_LIQUIDITY: return "NexusBase\\Nexus_Liquidity_Sweep_NR";
      case NX_FVG:       return "NexusBase\\Nexus_FVG_Retest_NR";
      case NX_STRUCTURE: return "NexusBase\\Nexus_Structure_Break_NR";
      case NX_VWAP:      return "NexusBase\\Nexus_Session_VWAP_NR_v1.10";
      case NX_SQUEEZE:   return "NexusBase\\Nexus_Volatility_Squeeze_NR";
      case NX_EMA:       return "NexusBase\\Nexus_EMA_Trend_Pullback_NR";
      case NX_KERNEL:    return "NexusBase\\Nexus_Causal_Kernel_NR";
      case NX_THREE:     return "NexusBase\\Nexus_Three_Candle_NR";
      case NX_VECTOR_M1: return "NexusBase\\H1_Vector_Factor_M1";
     }
   return "";
  }

bool IsSignal(const double price)
  {
   return price!=EMPTY_VALUE && price!=0.0 && MathIsValidNumber(price);
  }

double ClosedATR(const int i,const int total,
                 const double &hi[],const double &lo[],const double &cl[])
  {
   if(i+InpATRPeriod+1>=total) return 0.0;
   double sum=0.0;
   for(int j=i+1;j<=i+InpATRPeriod;j++)
     {
      double tr=hi[j]-lo[j];
      tr=MathMax(tr,MathAbs(hi[j]-cl[j+1]));
      tr=MathMax(tr,MathAbs(lo[j]-cl[j+1]));
      sum+=tr;
     }
   return sum/(double)InpATRPeriod;
  }

void PaintText(const string name,const datetime tm,const double price,
               const string value,const color ink,const int size=8)
  {
   if(!ObjectCreate(0,name,OBJ_TEXT,0,tm,price)) return;
   ObjectSetString(0,name,OBJPROP_TEXT,value);
   ObjectSetString(0,name,OBJPROP_FONT,"Tahoma");
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetInteger(0,name,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void HUD(const string tag,const int y,const string txt,const color ink,const int size)
  {
   const string obj=g_prefix+"HUD_"+tag;
   if(!ObjectCreate(0,obj,OBJ_LABEL,0,0,0)) return;
   ObjectSetInteger(0,obj,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,obj,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,obj,OBJPROP_XDISTANCE,16);
   ObjectSetInteger(0,obj,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,obj,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,obj,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,obj,OBJPROP_FONT,"Tahoma");
   ObjectSetString(0,obj,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,obj,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,obj,OBJPROP_SELECTABLE,false);
  }

void DrawLevel(const string tag,const datetime from,const datetime to,
               const double price,const color ink,const ENUM_LINE_STYLE style)
  {
   if(!ObjectCreate(0,g_prefix+tag,OBJ_TREND,0,from,price,to,price)) return;
   ObjectSetInteger(0,g_prefix+tag,OBJPROP_COLOR,ink);
   ObjectSetInteger(0,g_prefix+tag,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,g_prefix+tag,OBJPROP_STYLE,style);
   ObjectSetInteger(0,g_prefix+tag,OBJPROP_RAY_LEFT,false);
   ObjectSetInteger(0,g_prefix+tag,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(0,g_prefix+tag,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,g_prefix+tag,OBJPROP_HIDDEN,true);
  }

void DrawActivePlan(const VirtualTrade &trade,const datetime currentOpen)
  {
   if(!trade.active || !InpShowActiveTP_SL) return;
   int seconds=PeriodSeconds(_Period);
   if(seconds<=0) seconds=60;
   datetime end=currentOpen+(datetime)(seconds*5);
   if(end<=trade.entryTime) end=trade.entryTime+(datetime)(seconds*5);
   DrawLevel("TP",trade.entryTime,end,trade.tp,clrLimeGreen,STYLE_DASH);
   DrawLevel("SL",trade.entryTime,end,trade.stop,clrTomato,STYLE_DOT);
   DrawLevel("ENTRY",trade.entryTime,end,trade.entry,clrDodgerBlue,STYLE_DOT);
   PaintText(g_prefix+"TP_TX",end,trade.tp,"TP "+DoubleToString(trade.tp,_Digits),clrLimeGreen);
   PaintText(g_prefix+"SL_TX",end,trade.stop,"SL "+DoubleToString(trade.stop,_Digits),clrTomato);
   PaintText(g_prefix+"EN_TX",end,trade.entry,"ENTRADA "+DoubleToString(trade.entry,_Digits),clrDodgerBlue);
  }

void DrawClosed(const VirtualTrade &trade,const datetime endTime,
                const double endPrice,const double points,
                const bool wasTP,const bool wasSL,const bool expired,
                int &green,int &red,int &neutral,double &totalPts)
  {
   const double roundedPoints=(double)MathRound(points);
   totalPts+=roundedPoints;
   if(roundedPoints>0.0) green++;
   else if(roundedPoints<0.0) red++;
   else neutral++;
   if(trade.entryIndex>InpVisibleResultBars) return;

   string mark="0 pts";
   color ink=clrSilver;
   if(roundedPoints>0.0)
     {
      mark="+"+IntegerToString((int)roundedPoints)+" pts";
      ink=clrLimeGreen;
     }
   else if(roundedPoints<0.0)
     {
      mark="x "+IntegerToString((int)roundedPoints)+" pts";
      ink=clrTomato;
     }
   if(expired) mark+=" T";  // Exit after maximum holding bars
   if(InpShowResultPoints)
     {
      // Separate label from the candle body and arrow: no stacked numbers.
      const double labelY=(trade.dir>0 ? trade.entry-1.23*InpArrowDistanceATR*trade.atr :
                                          trade.entry+0.62*InpArrowDistanceATR*trade.atr);
      PaintText(g_prefix+"R_"+IntegerToString((long)trade.entryTime),
                trade.entryTime,labelY,mark,ink,8);
     }
   if(InpShowExitTags)
     {
      string tag="TIME";
      color tagInk=clrSilver;
      if(wasTP) {tag="TP";tagInk=clrLimeGreen;}
      else if(wasSL) {tag="SL";tagInk=clrTomato;}
      double bump=(trade.dir>0 ? 0.28 : -0.28)*trade.atr;
      PaintText(g_prefix+"EXIT_"+IntegerToString((long)trade.entryTime),
                endTime,endPrice+bump,tag,tagInk,8);
     }
  }

int OnInit()
  {
   if(InpHistoryBars<150 || InpVisibleResultBars<10 ||
      InpATRPeriod<2 || InpATRPeriod>300 ||
      InpStopBufferATR<0.0 || InpStopBufferATR>5.0 ||
      InpTP_R<=0.0 || InpTP_R>30.0 ||
      InpMaxHoldingBars<1 || InpMaxHoldingBars>2000 ||
      InpMinBarsBetweenSignals<0 || InpMinBarsBetweenSignals>300 ||
      InpArrowDistanceATR<0.2 || InpArrowDistanceATR>5.0 ||
      InpMaxSpreadPoints<0) return INIT_PARAMETERS_INCORRECT;
   if(InpModel==NX_VECTOR_M1 && _Period!=PERIOD_M1)
     {
      Print("Nexus: Vector Factor M1 supports M1 charts only.");
      return INIT_PARAMETERS_INCORRECT;
     }
   SetIndexBuffer(0,BuyOut,INDICATOR_DATA);
   SetIndexBuffer(1,SellOut,INDICATOR_DATA);
   SetIndexBuffer(2,VWAPOut,INDICATOR_DATA);
   SetIndexBuffer(3,UpperOut,INDICATOR_DATA);
   SetIndexBuffer(4,LowerOut,INDICATOR_DATA);
   ArraySetAsSeries(BuyOut,true);
   ArraySetAsSeries(SellOut,true);
   ArraySetAsSeries(VWAPOut,true);
   ArraySetAsSeries(UpperOut,true);
   ArraySetAsSeries(LowerOut,true);
   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);
   for(int k=0;k<5;k++) PlotIndexSetDouble(k,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   IndicatorSetString(INDICATOR_SHORTNAME,"Nexus Visual | "+ModelName()+" | TP e pontos");
   g_prefix="NXS_"+IntegerToString((long)ChartID())+"_"+
            IntegerToString((long)GetTickCount())+"_";
   g_handle=iCustom(_Symbol,_Period,ModelFile());
   if(g_handle==INVALID_HANDLE)
     {
      Print("Nexus: failed iCustom(",ModelFile(),") error=",GetLastError(),
            ". Compile the source to MQL5/Indicators/NexusBase first.");
      return INIT_FAILED;
     }
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,g_prefix,0,-1);
   if(g_handle!=INVALID_HANDLE) IndicatorRelease(g_handle);
  }

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],const double &open[],
                const double &high[],const double &low[],const double &close[],
                const long &tick_volume[],const long &volume[],const int &spread[])
  {
   if(g_handle==INVALID_HANDLE) return 0;
   if(rates_total<InpATRPeriod+25) return 0;
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(spread,true);
   const bool initial=(g_lastProcessedOpen==0);
   if(!initial && time[0]==g_lastProcessedOpen && prev_calculated>0)
      return rates_total;
   if(BarsCalculated(g_handle)<InpATRPeriod+25) return 0;

   int count=MathMin(InpHistoryBars+InpATRPeriod+40,rates_total);
   double srcBuy[],srcSell[],srcLine[],srcUpper[],srcLower[];
   ArraySetAsSeries(srcBuy,true);
   ArraySetAsSeries(srcSell,true);
   if(CopyBuffer(g_handle,0,0,count,srcBuy)<count) return 0;
   if(CopyBuffer(g_handle,1,0,count,srcSell)<count) return 0;
   if(InpModel==NX_VWAP && InpShowVWAPLine)
     {
      ArraySetAsSeries(srcLine,true);
      ArraySetAsSeries(srcUpper,true);
      ArraySetAsSeries(srcLower,true);
      if(CopyBuffer(g_handle,2,0,count,srcLine)<count) return 0;
      if(CopyBuffer(g_handle,3,0,count,srcUpper)<count) return 0;
      if(CopyBuffer(g_handle,4,0,count,srcLower)<count) return 0;
     }

   const bool realNewBar=(!initial && time[0]!=g_lastProcessedOpen);
   g_lastProcessedOpen=time[0];
   ArrayInitialize(BuyOut,EMPTY_VALUE);
   ArrayInitialize(SellOut,EMPTY_VALUE);
   ArrayInitialize(VWAPOut,EMPTY_VALUE);
   ArrayInitialize(UpperOut,EMPTY_VALUE);
   ArrayInitialize(LowerOut,EMPTY_VALUE);
   ObjectsDeleteAll(0,g_prefix,0,-1);

   int oldest=MathMin(InpHistoryBars,rates_total-InpATRPeriod-2);
   if(oldest>=count) oldest=count-1;
   int lastDirection=0;
   int lastEntryIndex=100000000;
   int pendingDir=0;
   int pendingSignalIndex=-1;
   double pendingATR=0.0,pendingStop=0.0;
   bool entryPending=false;
   VirtualTrade t;
   t.active=false;
   int greens=0,reds=0,neutral=0;
   double totalPoints=0.0;
   int latestDir=0;
   bool notify=false;

   for(int i=oldest;i>=0;i--)
     {
      // At the NEXT candle's OPEN enter the virtual trade and plot a small
      // arrow at this candle. Never backdate an entry to the signal candle.
      if(entryPending)
        {
         entryPending=false;
         const double nextOpen=open[i];
         double risk=pendingDir*(nextOpen-pendingStop);
         if(!t.active && risk>MathMax(4.0*_Point,0.1*pendingATR))
           {
            t.active=true;
            t.dir=pendingDir;
            t.entryTime=time[i];
            t.entryIndex=i;
            t.entry=nextOpen;
            t.stop=NormalizeDouble(pendingStop,_Digits);
            t.tp=NormalizeDouble(nextOpen+pendingDir*InpTP_R*risk,_Digits);
            t.atr=pendingATR;
            t.barsHeld=0;
            lastDirection=pendingDir;
            lastEntryIndex=i;
            double offset=MathMax(InpArrowDistanceATR*pendingATR,8*_Point);
            if(t.dir>0) BuyOut[i]=nextOpen-offset;
            else SellOut[i]=nextOpen+offset;
            if(i==0 && realNewBar && g_lastSoundEntry!=time[i])
              {
               notify=true;
               latestDir=pendingDir;
               g_lastSoundEntry=time[i];
              }
           }
        }
      if(i==0) break; // Do not use the CURRENT candle's high/low for results.

      // One virtual position at a time. TP and SL are evaluated in CLOSED
      // candles. If both levels touched in the same OHLC, SL goes FIRST.
      if(t.active)
        {
         t.barsHeld++;
         bool stopHit=(t.dir>0 ? low[i]<=t.stop : high[i]>=t.stop);
         bool targetHit=(t.dir>0 ? high[i]>=t.tp : low[i]<=t.tp);
         bool wasTime=false,finished=false;
         double exitPrice=0.0;
         if(stopHit)
           {
            // Gaps through stop use OPEN as a worse fill approximation.
            exitPrice=(t.dir>0 ? MathMin(open[i],t.stop) : MathMax(open[i],t.stop));
            finished=true;
           }
         else if(targetHit)
           {
            exitPrice=t.tp;
            finished=true;
           }
         else if(t.barsHeld>=InpMaxHoldingBars)
           {
            exitPrice=close[i];
            finished=true;
            wasTime=true;
           }
         if(finished)
           {
            double pts=t.dir*(exitPrice-t.entry)/_Point;
            DrawClosed(t,time[i],exitPrice,pts,
                       targetHit && !stopHit,stopHit,wasTime,
                       greens,reds,neutral,totalPoints);
            t.active=false;
           }
        }

      // VWAP line is shown only when VWAP model is selected. No extra arrows
      // from the base indicators are painted, avoiding overlapping signals.
      if(InpModel==NX_VWAP && InpShowVWAPLine)
        {
         VWAPOut[i]=srcLine[i];
         UpperOut[i]=srcUpper[i];
         LowerOut[i]=srcLower[i];
        }
      if(t.active || entryPending) continue;
      const bool buy=IsSignal(srcBuy[i]);
      const bool sell=IsSignal(srcSell[i]);
      if(buy==sell) continue;
      int dir=buy ? 1 : -1;
      if(InpOnePerDirection && dir==lastDirection) continue;
      if(lastEntryIndex-i<InpMinBarsBetweenSignals) continue;
      if(InpMaxSpreadPoints>0 && spread[i]>InpMaxSpreadPoints) continue;
      double atr=ClosedATR(i,rates_total,high,low,close);
      if(atr<=0.0) continue;
      double stop=(dir>0 ? low[i]-InpStopBufferATR*atr :
                              high[i]+InpStopBufferATR*atr);
      if(dir*(close[i]-stop)<=2*_Point) continue;
      // The underlying strategy decides DIRECTION. Our wrapper standardizes
      // display, timing, risk, exit and statistics only.
      pendingDir=dir;
      pendingATR=atr;
      pendingStop=stop;
      pendingSignalIndex=i;
      entryPending=true;
     }

   if(t.active) DrawActivePlan(t,time[0]);
   if(InpShowPanel)
     {
      HUD("NAME",16,"NEXUS / "+ModelName(),clrWhite,9);
      HUD("GREEN",37,"GREEN  "+IntegerToString(greens),clrLimeGreen,9);
      HUD("RED",57,"RED  "+IntegerToString(reds),clrTomato,9);
      const string points=(totalPoints>=0.0 ? "+" : "")+
                          IntegerToString((int)MathRound(totalPoints))+" pts";
      HUD("TOTAL",79,"TOTAL  "+points,(totalPoints>=0.0 ? clrLimeGreen:clrTomato),10);
      HUD("MORE",100,"Fechadas "+IntegerToString(greens+reds+neutral)+
          " | Aberta "+(t.active ? "1" : "0"),clrSilver,8);
      HUD("NOTE",119,"SIMULADO  |  sem taxas",clrSilver,7);
     }
   if(notify)
     {
      if(InpSoundAlert) PlaySound(InpSoundFile);
      string msg="NEXUS "+ModelName()+" | "+_Symbol+" "+
                 EnumToString(_Period)+" | "+(latestDir>0 ? "BUY" : "SELL")+
                 " na abertura da vela";
      if(InpPopupAlert) Alert(msg);
      if(InpPushNotification) SendNotification(msg);
     }
   ChartRedraw(0);
   return rates_total;
  }
//+------------------------------------------------------------------+