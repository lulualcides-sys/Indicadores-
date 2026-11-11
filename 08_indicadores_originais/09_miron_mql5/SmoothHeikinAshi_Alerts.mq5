//+------------------------------------------------------------------+
//|                                      SmoothHeikinAshi_Alerts.mq5  |
//|        Smoothed Heikin Ashi candles with color-change alerts      |
//+------------------------------------------------------------------+
#property copyright "Miron"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   1
#property indicator_label1  "Smoothed HA"
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrLimeGreen, clrTomato
#property indicator_width1  2

input int  InpMaPeriod   = 6;      // Smoothing period (EMA)
input bool InpAlertPopup = true;   // Popup alert on color change
input bool InpAlertPush  = false;  // Push notification on color change

double HaOpen[];
double HaHigh[];
double HaLow[];
double HaClose[];
double HaColor[];
double MaOpen[];
double MaHigh[];
double MaLow[];
double MaClose[];
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, HaOpen,  INDICATOR_DATA);
   SetIndexBuffer(1, HaHigh,  INDICATOR_DATA);
   SetIndexBuffer(2, HaLow,   INDICATOR_DATA);
   SetIndexBuffer(3, HaClose, INDICATOR_DATA);
   SetIndexBuffer(4, HaColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5, MaOpen,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(6, MaHigh,  INDICATOR_CALCULATIONS);
   SetIndexBuffer(7, MaLow,   INDICATOR_CALCULATIONS);
   SetIndexBuffer(8, MaClose, INDICATOR_CALCULATIONS);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   IndicatorSetString(INDICATOR_SHORTNAME, "Smoothed HA");
   return(INIT_SUCCEEDED);
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
   if(rates_total < 2) return(0);
   int start = (prev_calculated > 1) ? prev_calculated - 1 : 0;
   double k = 2.0 / (InpMaPeriod + 1.0);

   for(int i = start; i < rates_total; i++)
   {
      if(i == 0)
      {
         MaOpen[0] = open[0]; MaHigh[0] = high[0];
         MaLow[0]  = low[0];  MaClose[0] = close[0];
      }
      else
      {
         MaOpen[i]  = open[i]  * k + MaOpen[i-1]  * (1.0 - k);
         MaHigh[i]  = high[i]  * k + MaHigh[i-1]  * (1.0 - k);
         MaLow[i]   = low[i]   * k + MaLow[i-1]   * (1.0 - k);
         MaClose[i] = close[i] * k + MaClose[i-1] * (1.0 - k);
      }
      double haClose = (MaOpen[i] + MaHigh[i] + MaLow[i] + MaClose[i]) / 4.0;
      double haOpen;
      if(i == 0) haOpen = (MaOpen[i] + MaClose[i]) / 2.0;
      else       haOpen = (HaOpen[i-1] + HaClose[i-1]) / 2.0;
      double haHigh = MathMax(MaHigh[i], MathMax(haOpen, haClose));
      double haLow  = MathMin(MaLow[i],  MathMin(haOpen, haClose));
      HaOpen[i] = haOpen; HaHigh[i] = haHigh;
      HaLow[i]  = haLow;  HaClose[i] = haClose;
      HaColor[i] = (haClose >= haOpen) ? 0.0 : 1.0;
   }

   static datetime s_lastBar   = 0;
   static int      s_lastColor = -1;
   int last = rates_total - 2;
   if(last >= 0)
   {
      int col = (int)HaColor[last];
      if(s_lastColor != -1 && col != s_lastColor && time[last] != s_lastBar)
      {
         string dir = (col == 0) ? "BULLISH" : "BEARISH";
         string msg = _Symbol + " " + EnumToString((ENUM_TIMEFRAMES)_Period) +
                      " Smoothed HA -> " + dir;
         if(InpAlertPopup) Alert(msg);
         if(InpAlertPush)  SendNotification(msg);
         s_lastBar = time[last];
      }
      s_lastColor = col;
   }
   return(rates_total);
}
//+------------------------------------------------------------------+
