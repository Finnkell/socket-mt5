//+------------------------------------------------------------------+
//|                                                     test-zmq.mq5 |
//|                                Copyright 2021, BTK A.Intelligence|
//|                                            http://www.btk.com.br |
//+------------------------------------------------------------------+
#include <Zmq/Zmq.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade m_trade;
CPositionInfo m_position;

extern string PROJECT_NAME = "TradeServer";
extern string ZEROMQ_PROTOCOL = "tcp";
extern string HOSTNAME = "*";
extern int REP_PORT = 5555;
extern int MILLISECOND_TIMER = 1;  // 1 millisecond

extern string t0 = "--- Trading Parameters ---";
extern int MagicNumber = 123456;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Context context(PROJECT_NAME);
Socket repSocket(context, ZMQ_REP);

uchar myData[];
ZmqMsg zmq_request;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
  EventSetMillisecondTimer(MILLISECOND_TIMER);

  Print("[REP] Binding MT5 Server to Socket on Port " + IntegerToString(REP_PORT) + "..");

  repSocket.bind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, REP_PORT));

  repSocket.setLinger(1000);

  repSocket.setSendHighWaterMark(5);

  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
  Print("[REP] Unbinding MT5 Server from Socket on Port " + IntegerToString(REP_PORT) + "..");
  repSocket.unbind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, REP_PORT));
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer() {
  repSocket.recv(zmq_request, true);
  MessageHandler(zmq_request);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MessageHandler(ZmqMsg &localRequest) {
  ZmqMsg reply;

  string components[];

  if(localRequest.size() > 0) {
    ArrayResize(myData, localRequest.size());
    localRequest.getData(myData);

    string dataStr = CharArrayToString(myData);

    ParseZmqMessage(dataStr, components);
    InterpretZmqMessage(components);

  }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InterpretZmqMessage(string& compArray[]) {
  Print("ZMQ: Interpreting Message..");

  int switch_action = 0;
  string volume;

  if (compArray[0] == "TRADE" && compArray[1] == "OPEN")
    switch_action = 1;
  else if (compArray[0] == "RATES")
    switch_action = 2;
  else if (compArray[0] == "TRADE" && compArray[1] == "CLOSE")
    switch_action = 3;
  else if (compArray[0] == "DATA")
    switch_action = 4;

  string ret = "";
  int ticket = -1;
  bool ans = false;

  MqlRates rates[];
  ArraySetAsSeries(rates, true);

  int price_count = 0;

  ZmqMsg msg("[SERVER] Processing");

  double tick = SymbolInfoDouble(compArray[3], SYMBOL_LAST);

  switch(switch_action) {

  case 1:
    if (compArray[2] == "0") {
      repSocket.send("WINV21|100|MKT|0|DAY", false);
      return;
    }

    // for(int i = 0; i < PositionsTotal(); i++)
    //   {
    //    string symbol = PositionGetSymbol(i);
    //    ulong magic_number = PositionGetInteger(POSITION_MAGIC);

    //    if(symbol == Symbol() && magic_number == compArray[9])
    //      {
    //       ulong position_ticket = PositionGetInteger(POSITION_TICKET);

    //       double position_profit = PositionGetDouble(POSITION_PROFIT);
    //       double position_price_open = PositionGetDouble(POSITION_PRICE_OPEN);
    //       double position_price_sl = PositionGetDouble(POSITION_SL);
    //       double position_price_tp = PositionGetDouble(POSITION_TP);
    //       double position_volume = PositionGetDouble(POSITION_VOLUME);

    //       string str = IntegerToString(position_ticket) + "|" + DoubleToString(position_profit) + "|" + DoubleToString(position_price_open) + "|" + DoubleToString(position_price_sl) + "|" + DoubleToString(position_price_tp) + "|" + DoubleToString(position_volume);

    //       Print(str);

    //       repSocket.send(str, false);

    //       return;

    //      }
    //   }

    break;

  case 2:
    ret = "N/A";
    if(ArraySize(compArray) > 1)
      ret = GetCurrent(compArray[1]);
    repSocket.send(ret, false);
    break;

  case 3:
    repSocket.send(msg, false);
    break;

  case 4:
    ret = "";
    // Format: DATA|SYMBOL|TIMEFRAME|START_DATETIME|END_DATETIME
    price_count = CopyRates(compArray[1], TFMigrate(StringToInteger(compArray[2])), StringToTime(compArray[3]), StringToTime(compArray[4]), rates);

    if (price_count > 0) {
      for(int i = 0; i < price_count; i++ ) {
        ret = ret + "|" + StringFormat("%.2f,%.2f,%.2f,%.2f,%d,%d", rates[i].open, rates[i].low, rates[i].high, rates[i].close, rates[i].tick_volume, rates[i].real_volume);
      }

      Print("Sending: " + ret);

      repSocket.send(ret, false);
    }
    break;

  default:
    break;
  }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ParseZmqMessage(string & message, string & retArray[]) {
  Print("Parsing: " + message);

  string sep = "|";
  ushort u_sep = StringGetCharacter(sep, 0);

  int splits = StringSplit(message, u_sep, retArray);

  for(int i = 0; i < splits; i++) {
    Print(IntegerToString(i) + ") " + retArray[i]);
  }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetVolume(string symbol, datetime start_time, datetime stop_time) {
  long volume_array[1];
  CopyRealVolume(symbol, PERIOD_M1, start_time, stop_time, volume_array);

  return(StringFormat("%d", volume_array[0]));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetCurrent(string symbol) {
  MqlTick Last_tick;
  MqlBookInfo bookArray[];

  SymbolInfoTick(symbol, Last_tick);

  double bid = Last_tick.bid;
  double ask = Last_tick.ask;

  bool getBook = MarketBookGet(symbol, bookArray);

  long buy_volume = 0;
  long sell_volume = 0;
  long buy_volume_market = 0;
  long sell_volume_market = 0;

  if (getBook) {
    for (int i = 0; i < ArraySize(bookArray); i++ ) {
      if (bookArray[i].type == BOOK_TYPE_SELL)
        sell_volume += bookArray[i].volume_real;
      else if (bookArray[i].type == BOOK_TYPE_BUY)
        buy_volume += bookArray[i].volume_real;
      else if (bookArray[i].type == BOOK_TYPE_BUY_MARKET)
        buy_volume_market += bookArray[i].volume_real;
      else
        sell_volume_market += bookArray[i].volume_real;
    }
  }

  long tick_volume = Last_tick.volume;
  long real_volume = Last_tick.volume_real;

  MarketBookAdd(symbol);

  return(StringFormat("%.2f,%.2f,%d,%d,%d,%d,%d,%d", bid, ask, buy_volume, sell_volume, tick_volume, real_volume, buy_volume_market, sell_volume_market));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES TFMigrate(int tf) {
  switch(tf) {
  case 0:
    return(PERIOD_CURRENT);
  case 1:
    return(PERIOD_M1);
  case 5:
    return(PERIOD_M5);
  case 15:
    return(PERIOD_M15);
  case 30:
    return(PERIOD_M30);
  case 60:
    return(PERIOD_H1);
  case 240:
    return(PERIOD_H4);
  case 1440:
    return(PERIOD_D1);
  case 10080:
    return(PERIOD_W1);
  case 43200:
    return(PERIOD_MN1);
  case 2:
    return(PERIOD_M2);
  case 3:
    return(PERIOD_M3);
  case 4:
    return(PERIOD_M4);
  case 6:
    return(PERIOD_M6);
  case 10:
    return(PERIOD_M10);
  case 12:
    return(PERIOD_M12);
  case 16385:
    return(PERIOD_H1);
  case 16386:
    return(PERIOD_H2);
  case 16387:
    return(PERIOD_H3);
  case 16388:
    return(PERIOD_H4);
  case 16390:
    return(PERIOD_H6);
  case 16392:
    return(PERIOD_H8);
  case 16396:
    return(PERIOD_H12);
  case 16408:
    return(PERIOD_D1);
  case 32769:
    return(PERIOD_W1);
  case 49153:
    return(PERIOD_MN1);
  default:
    return(PERIOD_CURRENT);
  }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
