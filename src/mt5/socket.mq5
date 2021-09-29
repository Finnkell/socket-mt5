//+------------------------------------------------------------------+
//|                                                       socket.mq5 |
//|                                BTK A.Intelligence - Eric Batista |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "BTK A.Intelligence - Eric Batista"
#property link      "https://www.btk.com.br/"
#property version   "1.0"
#property strict

#include <Zmq/Zmq.mqh>

extern string PROJECT_NAME            = "BTK_SOCKET_CONNECTION";
extern string ZEROMQ_PROTOCOL         = "tcp";
extern string HOSTNAME                = "*";
extern int    PUSH_PORT               = 32768;
extern int    PULL_PORT               = 32769;
extern int    PUB_PORT                = 32770;
extern int    MILLISECOND_TIMER       = 1;
extern int    MILLISECOND_TIMER_PRICE = 500;
extern bool   DMA_MODE                = true;

extern int    maximum_orders      = 1;
extern double maximum_lot_size    = 100;
extern int    maximum_slippage    = 3;

extern bool   publish_marketdata  = false;
extern bool   publish_marketrates = false;

extern long   last_update_milis   = GetTickCount();

extern string publish_symbols[];
extern string publish_symbols_last_tick[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
extern Context context(PROJECT_NAME);
extern Socket pushSocket(context, ZMQ_PUSH);
extern Socket pullSocket(context, ZMQ_PULL);
extern Socket pubSocket(context, ZMQ_PUB);

extern uchar _data[];

extern ZmqMsg request;

class Instrument {
protected:
   string            _name;
   string            _symbol;
   ENUM_TIMEFRAMES   _timeframe;
   datetime          _last_pub_rate;

public:
   Instrument() {
      _symbol = "";
      _name = "";
      _timeframe = PERIOD_CURRENT;
      _last_pub_rate = 0;
   }

   Instrument(const string symbol, const string name, const ENUM_TIMEFRAMES timeframe, const datetime last_pub_rate) {
      _symbol = symbol;
      _name = name;
      _timeframe = timeframe;
      _last_pub_rate = last_pub_rate;
   }

   string get_symbol() {
      return _symbol;
   }

   string get_name() {
      return _name;
   }

   ENUM_TIMEFRAMES get_timeframe() {
      return _timeframe;
   }

   datetime get_last_publish_timestamp() {
      return _last_pub_rate;
   }

   int get_rates(MqlRates &rates[], int count) {
      if (StringLen(_symbol) > 0) {
         return CopyRates(_symbol, _timeframe, 0, count, rates);
      }

      return 0;
   }

   void set_symbol(string symbol) {
      _symbol = symbol;
   }
   
   void set_name(string name) {
      _name = name;
   }

   void set_timeframe(ENUM_TIMEFRAMES timeframe) {
      _timeframe = timeframe;
   }

   void set_last_publish_timestamp(datetime tmstmp) {
      _last_pub_rate = tmstmp;
   }

   void setup(string arg_symbol, ENUM_TIMEFRAMES arg_timeframe) {
      _symbol = arg_symbol;
      _timeframe = arg_timeframe;
      _name = _symbol + "_" + EnumToString((ENUM_TIMEFRAMES) arg_timeframe);
      _last_pub_rate = 0;
   }
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   EventSetMillisecondTimer(MILLISECOND_TIMER);

   Print("[REP] Binding MT5 Server to Socket on Port " + IntegerToString(REP_PORT) + "..");

   repSocket.bind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, REP_PORT));

   repSocket.setLinger(1000);

   repSocket.setSendHighWaterMark(5);

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   EventKillTimer();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---

}
//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer(void) {

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ZmqMsg message_handler() {
   return "";
}
//+------------------------------------------------------------------+
