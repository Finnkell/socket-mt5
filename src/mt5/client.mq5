//+------------------------------------------------------------------+
//|                                                     test-zmq.mq5 |
//|                                Copyright 2021, BTK A.Intelligence|
//|                                            http://www.btk.com.br |
//+------------------------------------------------------------------+
#include <Zmq\Zmq.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CTrade m_trade;
CPositionInfo m_position;

extern string PROJECT_NAME = "TradeServer";
extern string ZEROMQ_PROTOCOL = "tcp";
extern string HOSTNAME = "localhost";
extern int    PORT = 5001;
extern int    MILLISECOND_TIMER = 1;  // 1 millisecond

extern string t0 = "--- Trading Parameters ---";
extern int    MagicNumber = 123456;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Context context(PROJECT_NAME);
Socket dealerSocket(context, ZMQ_DEALER);

uchar myData[];
ZmqMsg zmq_request;

PollItem items[1];


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    //EventSetTimer(1);
    EventSetMillisecondTimer(MILLISECOND_TIMER);

    Print("[DEALER] Connecting MT5 Server to Socket on Port " + IntegerToString(PORT) + "..");

    dealerSocket.connect(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PORT));
    dealerSocket.setIdentity("magicnumber");

    dealerSocket.fillPollItem(items[0], ZMQ_POLLIN);

    //zmq_poll(items, ArraySize(items), 500);

    //dealerSocket.setLinger(1000);
    //dealerSocket.setSendHighWaterMark(5);

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print("[REP] Unbinding MT5 Server from Socket on Port " + IntegerToString(PORT) + "..");
    dealerSocket.unbind(StringFormat("%s://%s:%d", ZEROMQ_PROTOCOL, HOSTNAME, PORT));
}

//+------------------------------------------------------------------+
//| Expert timer function                                            |
//+------------------------------------------------------------------+
void OnTimer() {

    // 'TRADE|OPEN|MAGIC|TICKER|VOLUME|ORDER_TYPE|TIF|SIDE'

    //  Initialize polling set
    
    string send_message = StringFormat("TRADE|OPEN|%s|%s|%lf|MKT|DAY|BUY", IntegerToString(MagicNumber), "XBV1 Index", 1.0);
    dealerSocket.send(send_message, false);

    ZmqMsg message;
    Socket::poll(items, 500);

    if(items[0].hasInput()) {
        dealerSocket.recv(zmq_request, true);
        MessageHandler(zmq_request);
    }
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
        //InterpretZmqMessage(components);

    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InterpretZmqMessage(string& compArray[]) {
    Print("ZMQ: Interpreting Message..");

    string send_message = StringFormat("TRADE|OPEN|%d|%s|%lf|MKT|DAY|BUY", MagicNumber, "XBV1 Index", 1.0);
    dealerSocket.send(send_message, false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ParseZmqMessage(string & message, string & retArray[]) {
    Print("Parsing COM UM: " + message);

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
