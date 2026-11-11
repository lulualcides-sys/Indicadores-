//+------------------------------------------------------------------+
//|                                             TradeInfoPanel.mq5    |
//|      On-chart panel: balance, equity, floating P/L, spread, etc.  |
//+------------------------------------------------------------------+
#property copyright "Miron"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

input int   InpX     = 20;         // Panel X (pixels)
input int   InpY     = 40;         // Panel Y (pixels)
input color InpColor = clrWhite;   // Text color

string g_prefix = "TIP_";
string g_rows[7] = {"symbol", "balance", "equity", "profit",
                    "margin", "freemargin", "spread"};
//+------------------------------------------------------------------+
int OnInit()
{
   Lbl(g_prefix + "title", "Trade Info", InpX, InpY - 20, 11);
   for(int i = 0; i < 7; i++)
      Lbl(g_prefix + g_rows[i], "", InpX, InpY + i * 18, 10);
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
   double bal    = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq     = AccountInfoDouble(ACCOUNT_EQUITY);
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);
   double freem  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   long   spr    = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   Set(g_prefix + "symbol", "Symbol:  " + _Symbol, InpColor);
   Set(g_prefix + "balance", StringFormat("Balance: %.2f", bal), InpColor);
   Set(g_prefix + "equity",  StringFormat("Equity:  %.2f", eq),  InpColor);
   Set(g_prefix + "profit",  StringFormat("Float P/L: %.2f", profit),
       (profit >= 0 ? clrLimeGreen : clrTomato));
   Set(g_prefix + "margin",  StringFormat("Margin:  %.2f", margin), InpColor);
   Set(g_prefix + "freemargin", StringFormat("Free:    %.2f", freem), InpColor);
   Set(g_prefix + "spread",  StringFormat("Spread:  %d", (int)spr), InpColor);
   ChartRedraw(0);
   return(rates_total);
}
//+------------------------------------------------------------------+
void Lbl(string name, string text, int x, int y, int fs)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, InpColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fs);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}
void Set(string name, string text, color clr)
{
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
}
//+------------------------------------------------------------------+
