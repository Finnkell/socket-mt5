# Introduction 
TODO: Give a short introduction of your project. Let this section explain the objectives or the motivation behind this project. 

# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)

```cpp

  // 1) Trading
  // TRADE|ACTION|TYPE|SYMBOL|PRICE|SL|TP|COMMENT|TICKET
  // e.g. TRADE|OPEN|1|EURUSD|0|50|50|R-to-MetaTrader4|12345678

  // The 12345678 at the end is the ticket ID, for MODIFY and CLOSE.

  // 2) Data Requests

  // 2.1) RATES|SYMBOL   -> Returns Current Bid/Ask

  // 2.2) DATA|SYMBOL|TIMEFRAME|START_DATETIME|END_DATETIME

  // NOTE: datetime has format: D'2015.01.01 00:00'

  /*
    compArray[0] = TRADE or RATES
    If RATES -> compArray[1] = Symbol

    If TRADE ->
        compArray[0] = TRADE
        compArray[1] = ACTION (e.g. OPEN, MODIFY, CLOSE)
        compArray[2] = TYPE (e.g. OP_BUY, OP_SELL, etc - only used when ACTION=OPEN)

        // ORDER TYPES:
        // https://docs.mql4.com/constants/tradingconstants/orderproperties

        // OP_BUY = 0
        // OP_SELL = 1
        // OP_BUYLIMIT = 2
        // OP_SELLLIMIT = 3
        // OP_BUYSTOP = 4
        // OP_SELLSTOP = 5

        compArray[3] = Symbol (e.g. EURUSD, etc.)
        compArray[4] = Open/Close Price (ignored if ACTION = MODIFY)
        compArray[5] = SL
        compArray[6] = TP
        compArray[7] = Trade Comment
  */

```