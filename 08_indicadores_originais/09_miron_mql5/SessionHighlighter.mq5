//+------------------------------------------------------------------+
//|                                          SessionHighlighter.mq5   |
//|      Highlights Asian / London / New York sessions with boxes     |
//+------------------------------------------------------------------+
#property copyright "Miron"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

input int   InpDays      = 5;    // Days back to draw
input int   InpAsiaStart = 0;    // Asia start hour (server time)
input int   InpAsiaEnd   = 8;    // Asia end hour
input int   InpLonStart  = 8;    // London start hour
input int   InpLonEnd    = 16;   // London end hour
input int   InpNYStart   = 13;   // New York start hour
input int   InpNYEnd     = 21;   // New York end hour
input color InpAsiaColor = clrDodgerBlue;
input color InpLonColor  = clrOrange;
input color InpNYColor   = clrMediumOrchid;

string g_prefix = "SESS_";
//+------------------------------------------------------------------+
int OnInit(){ return(INIT_SUCCEEDED); }
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
   static datetime s_lastBuilt = 0;
   datetime cur = time[rates_total - 1];
   if(cur == s_lastBuilt && prev_calculated > 0)
      return(rates_total);
   s_lastBuilt = cur;

   ObjectsDeleteAll(0, g_prefix);

   MqlDateTime dt;
   datetime now = TimeCurrent();
   for(int d = 0; d < InpDays; d++)
   {
      datetime dayStart = now - d * 86400;
      TimeToStruct(dayStart, dt);
      dt.hour = 0; dt.min = 0; dt.sec = 0;
      datetime base = StructToTime(dt);
      DrawBox(g_prefix + "asia" + (string)d, base + InpAsiaStart * 3600,
              base + InpAsiaEnd * 3600, InpAsiaColor);
      DrawBox(g_prefix + "lon" + (string)d, base + InpLonStart * 3600,
              base + InpLonEnd * 3600, InpLonColor);
      DrawBox(g_prefix + "ny" + (string)d, base + InpNYStart * 3600,
              base + InpNYEnd * 3600, InpNYColor);
   }
   ChartRedraw(0);
   return(rates_total);
}
//+------------------------------------------------------------------+
void DrawBox(string name, datetime t1, datetime t2, color clr)
{
   MqlRates rates[];
   int copied = CopyRates(_Symbol, _Period, t1, t2, rates);
   if(copied <= 0) return;
   double hi = rates[0].high, lo = rates[0].low;
   for(int i = 1; i < copied; i++)
   {
      if(rates[i].high > hi) hi = rates[i].high;
      if(rates[i].low  < lo) lo = rates[i].low;
   }
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, hi, t2, lo);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, hi);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, lo);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}
//+------------------------------------------------------------------+
