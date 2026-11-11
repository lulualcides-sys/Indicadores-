//+------------------------------------------------------------------+
//|                                            ATR_SLTP_Levels.mq5    |
//|     Draws ATR-based Stop Loss / Take Profit levels on the chart   |
//+------------------------------------------------------------------+
#property copyright "Miron"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

input int    InpAtrPeriod = 14;    // ATR period
input double InpSLmult    = 1.5;   // Stop Loss = ATR x
input double InpTPmult    = 2.0;   // Take Profit = ATR x
input color  InpBuyColor  = clrLimeGreen;
input color  InpSellColor = clrTomato;

string g_prefix = "ATRLV_";
int    g_atr;
//+------------------------------------------------------------------+
int OnInit()
{
   g_atr = iATR(_Symbol, _Period, InpAtrPeriod);
   if(g_atr == INVALID_HANDLE) return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){ ObjectsDeleteAll(0, g_prefix); }
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   double atrBuf[];
   if(CopyBuffer(g_atr, 0, 0, 1, atrBuf) <= 0) return(rates_total);
   double atr   = atrBuf[0];
   double price = close[rates_total - 1];
   Level(g_prefix + "buyTP", price + atr * InpTPmult, InpBuyColor,  "Buy TP");
   Level(g_prefix + "buySL", price - atr * InpSLmult, InpSellColor, "Buy SL");
   Level(g_prefix + "selTP", price - atr * InpTPmult, InpBuyColor,  "Sell TP");
   Level(g_prefix + "selSL", price + atr * InpSLmult, InpSellColor, "Sell SL");
   ChartRedraw(0);
   return(rates_total);
}
//+------------------------------------------------------------------+
void Level(string name, double p, color clr, string text)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, p);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   }
   ObjectSetDouble(0, name, OBJPROP_PRICE, p);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetString(0, name, OBJPROP_TEXT, text + " " + DoubleToString(p, _Digits));
}
//+------------------------------------------------------------------+
