# SimpleIntradayTickExample.py
from __future__ import print_function
from __future__ import absolute_import

import datetime
from optparse import OptionParser

import os
import platform as plat
import sys
# if sys.version_info >= (3, 8) and plat.system().lower() == "windows":
#     # pylint: disable=no-member
#     with os.add_dll_directory(os.getenv('BLPAPI_LIBDIR')):
#         import blpapi
# else:
import blpapi

def parseCmdLine():
    parser = OptionParser(description="Retrieve reference data.")
    parser.add_option("-a",
                      "--ip",
                      dest="host",
                      help="server name or IP (default: %default)",
                      metavar="ipAddress",
                      default="localhost")
    parser.add_option("-p",
                      dest="port",
                      type="int",
                      help="server port (default: %default)",
                      metavar="tcpPort",
                      default=8194)

    poptions,_ = parser.parse_args()

    return poptions


def getPreviousTradingDate():
    tradedOn = datetime.date.today()

    while True:
        try:
            tradedOn -= datetime.timedelta(days=1)
        except OverflowError:
            return None

        if tradedOn.weekday() not in [5, 6]:
            return tradedOn


def main():
    options = parseCmdLine()

    # Fill SessionOptions
    sessionOptions = blpapi.SessionOptions()
    sessionOptions.setServerHost(options.host)
    sessionOptions.setServerPort(options.port)

    print("Connecting to %s:%d" % (options.host, options.port))

    # Create a Session
    session = blpapi.Session(sessionOptions)

    # Start a Session
    if not session.start():
        print("Failed to start session.")
        return

    if not session.openService("//blp/refdata"):
        print("Failed to open //blp/refdata")
        return

    refDataService = session.getService("//blp/refdata")
    request = refDataService.createRequest("IntradayTickRequest")
    request.set("security", "VOD LN Equity")
    request.getElement("eventTypes").appendValue("TRADE")
    request.getElement("eventTypes").appendValue("AT_TRADE")
    request.set("includeConditionCodes", True)

    tradedOn = getPreviousTradingDate()
    if not tradedOn:
        print("unable to get previous trading date")
        return

    startTime = datetime.datetime.combine(tradedOn, datetime.time(13, 30))
    request.set("startDateTime", startTime)

    endTime = datetime.datetime.combine(tradedOn, datetime.time(13, 35))
    request.set("endDateTime", endTime)

    print("Sending Request:", request)
    session.sendRequest(request)

    try:
        # Process received events
        while(True):
            # We provide timeout to give the chance to Ctrl+C handling:
            ev = session.nextEvent(500)
            for msg in ev:
                print(msg)
            # Response completly received, so we could exit
            if ev.eventType() == blpapi.Event.RESPONSE:
                break
    finally:
        # Stop the session
        session.stop()

if __name__ == "__main__":
    print("SimpleIntradayTickExample")
    try:
        main()
    except KeyboardInterrupt:
        print("Ctrl+C pressed. Stopping...")