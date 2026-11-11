//+------------------------------------------------------------------+
//|                                          SupplyDemandZones.mq5    |
//|     Auto-detects swing highs/lows and draws S/D zone rectangles   |
//+------------------------------------------------------------------+
#property copyright "Miron"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

input int   InpSwing    = 3;    // Bars each side for a swing
input int   InpScanBars = 400;  // How many bars to scan
input int   InpMaxZones = 6;    // Max zones per type
input color InpSupply   = clrTomato;    // Supply (resistance) color
input color InpDemand   = clrLimeGreen; // Demand (support) color

string g_prefix = "SD_";
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
   if(time[rates_total - 1] == s_lastBuilt && prev_calculated > 0)
      return(rates_total);
   s_lastBuilt = time[rates_total - 1];

   ObjectsDeleteAll(0, g_prefix);

   int scan = MathMin(InpScanBars, rates_total - InpSwing - 1);
   datetime rightEdge = time[rates_total - 1] + PeriodSeconds(_Period) * 10;
   int supCount = 0, demCount = 0;
   for(int i = rates_total - InpSwing - 1; i >= rates_total - scan && i > InpSwing; i--)
   {
      bool isHigh = true, isLow = true;
      for(int j = 1; j <= InpSwing; j++)
      {
         if(high[i] < high[i-j] || high[i] < high[i+j]) isHigh = false;
         if(low[i]  > low[i-j]  || low[i]  > low[i+j])  isLow  = false;
      }
      if(isHigh && supCount < InpMaxZones)
      {
         DrawZone(g_prefix + "sup" + (string)i, time[i], rightEdge,
                  high[i], MathMax(open[i], close[i]), InpSupply);
         supCount++;
      }
      if(isLow && demCount < InpMaxZones)
      {
         DrawZone(g_prefix + "dem" + (string)i, time[i], rightEdge,
                  MathMin(open[i], close[i]), low[i], InpDemand);
         demCount++;
      }
   }
   ChartRedraw(0);
   return(rates_total);
}
//+------------------------------------------------------------------+
void DrawZone(string name, datetime t1, datetime t2, double p1, double p2, color clr)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, p1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}
//+------------------------------------------------------------------+
