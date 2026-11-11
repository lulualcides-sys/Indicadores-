//+------------------------------------------------------------------+
//|                                          MTF_RSI_Dashboard.mq5    |
//|              Multi-timeframe RSI dashboard as an on-chart panel   |
//+------------------------------------------------------------------+
#property copyright "Miron"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

input int   InpRSIPeriod  = 14;      // RSI period
input int   InpOverbought = 70;      // Overbought level
input int   InpOversold   = 30;      // Oversold level
input int   InpXOffset    = 20;      // Panel X (pixels)
input int   InpYOffset    = 30;      // Panel Y (pixels)
input color InpTextColor  = clrWhite; // Neutral text color

string g_prefix = "MTF_RSI_";
ENUM_TIMEFRAMES g_tf[4] = {PERIOD_M15, PERIOD_H1, PERIOD_H4, PERIOD_D1};
string g_tfNames[4]     = {"M15", "H1", "H4", "D1"};
int    g_handle[4];
//+------------------------------------------------------------------+
int OnInit()
{
   for(int i = 0; i < 4; i++)
   {
      g_handle[i] = iRSI(_Symbol, g_tf[i], InpRSIPeriod, PRICE_CLOSE);
      if(g_handle[i] == INVALID_HANDLE)
      {
         Print("Failed to create RSI handle for ", g_tfNames[i]);
         return(INIT_FAILED);
      }
   }
   CreatePanel();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, g_prefix);
}
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
   UpdatePanel();
   return(rates_total);
}
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontsize = 10)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
}
//+------------------------------------------------------------------+
void CreatePanel()
{
   CreateLabel(g_prefix + "title", "RSI Dashboard", InpXOffset, InpYOffset, InpTextColor, 11);
   for(int i = 0; i < 4; i++)
      CreateLabel(g_prefix + "row" + (string)i, g_tfNames[i] + ": ...",
                  InpXOffset, InpYOffset + 22 + i * 18, InpTextColor);
}
//+------------------------------------------------------------------+
void UpdatePanel()
{
   double buf[];
   for(int i = 0; i < 4; i++)
   {
      if(CopyBuffer(g_handle[i], 0, 0, 1, buf) <= 0)
         continue;
      double val = buf[0];
      color  clr = InpTextColor;
      string state = "neutral";
      if(val >= InpOverbought)      { clr = clrTomato;    state = "OVERBOUGHT"; }
      else if(val <= InpOversold)   { clr = clrLimeGreen; state = "OVERSOLD";   }
      string txt = StringFormat("%-4s %6.2f  %s", g_tfNames[i], val, state);
      ObjectSetString(0, g_prefix + "row" + (string)i, OBJPROP_TEXT, txt);
      ObjectSetInteger(0, g_prefix + "row" + (string)i, OBJPROP_COLOR, clr);
   }
   ChartRedraw(0);
}
//+------------------------------------------------------------------+
