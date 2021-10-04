import zmq
import blpapi
import sys
from time import sleep

SESSION_STARTED             = blpapi.Name('SessionStarted')
SESSION_STARTUP_FAILURE     = blpapi.Name('SessionStartupFailure')
SERVICE_OPENED              = blpapi.Name("ServiceOpened")
SERVICE_OPEN_FAILURE        = blpapi.Name("ServiceOpenFailure")
ERROR_INFO                  = blpapi.Name("ErrorInfo")
CREATE_ORDER_AND_ROUTE_EX   = blpapi.Name('CreateOrderAndRouteEx')

d_emsx_service = '//blp/emapisvc_beta'
d_host = 'localhost'
d_port = 8194
b_end = False

data = None

class SessionEventHandler():
    
    def process_event(self, event, session):

        try:
            if event.eventType() == blpapi.Event.SESSION_STATUS:
                self.process_session_status_event(event, session)

            elif event.eventType() == blpapi.Event.SERVICE_STATUS:
                self.process_service_status_event(event)

            elif event.eventType() == blpapi.Event.RESPONSE:
                self.process_response_event(event)

            else:
                self.process_misc_events(event)

        except:
            print(f'Exception: {sys.exc_info()[0]}')

        return False


    def process_session_status_event(self, event, session):
        print('Processing SESSION_STATUS event')

        for msg in event:
            if msg.messageType() == SESSION_STARTED:
                print('Session started....')
                session.openServiceAsync(d_emsx_service)

            elif msg.messageType() == SESSION_STARTUP_FAILURE:
                print(f'Error: Session startup failure {sys.stderr}')
            
            else:
                print(msg)

    def process_service_status_event(self, event, session):
        print('Processing SERVICE_STATUS event')

        global data

        for msg in event:
            if msg.messageType() == SERVICE_OPENED:
                print('Service opened....')

                service = session.getService(d_emsx_service)

                # request = service.createRequest("CreateAndRouteEx")
                request = service.createRequest("CreateOrder")

                symbol = ''

                print(data)

                if data[0].contains('WIN'):
                    symbol = 'XBV1 Index'
                    print(f"Symbol: {symbol}")
                else:
                    symbol = data[0] + 'Bz Equity'
                    print(f"Symbol: {symbol}")

                if data[3] == 0:
                    order_side = 'BUY'
                elif data[3] == 1:
                    order_side = 'SELL'

                request.set("EMSX_TICKER", symbol)
                request.set("EMSX_AMOUNT", int(data[1]))
                request.set("EMSX_ORDER_TYPE", data[2])
                request.set("EMSX_SIDE", order_side)
                request.set("EMSX_TIF", data[4])
                request.set("EMSX_HAND_INSTRUCTION", "ANY")
                request.set("EMSX_BROKER", "BMTB")

                print(f'Request: {request.toString()}')

                self.request_ID = blpapi.CorrelationId()

                session.sendRequest(request, correlationId=self.request_ID)

            elif msg.messageType() == SERVICE_OPEN_FAILURE:
                print(f'Error: service failed to open {sys.stderr}')


        def process_response_event(self, event):
            print('Processing Response event...')

            for msg in event:
                print(f'Message: {msg.toString()}')

                if msg.correlationIds()[0].value() == self.request_ID.value():
                    print(f'Message Type: {msg.messageType()}')
                    print(f'Correlation ID: {msg.correlationIds()[0].value()}')

                    if msg.messageType() == ERROR_INFO:
                        error_code = msg.getElementAsInteger('ERROR_CODE')
                        error_message = msg.getElementAsString('ERROR_MESSAGE')

                        print(f'Error code: {error_code}, Error message: {error_message}')
                    elif msg.messageType() == CREATE_ORDER_AND_ROUTE_EX:
                        emsx_sequence = msg.getElementAsInteger("EMSX_SEQUENCE")
                        emsx_route_id = msg.getElementAsInteger("EMSX_ROUTE_ID")
                        message = msg.getElementAsString("MESSAGE")
                        print ("EMSX_SEQUENCE: %d\tEMSX_ROUTE_ID: %d\tMESSAGE: %s" % (emsx_sequence,emsx_route_id,message))
                    elif msg.messageType() == CREATE_ORDER_AND_ROUTE_EX:
                        emsx_sequence = msg.getElementAsInteger("EMSX_SEQUENCE")
                        message = msg.getElementAsString("MESSAGE")
                        print ("EMSX_SEQUENCE: %d\tMESSAGE: %s" % (emsx_sequence,message))

                global b_end
                b_end = True

        def process_misc_events(self, event):
            print(f"Processing {event.eventType()} event")
            
            for msg in event:
                print("MESSAGE: {msg.tostring()}")


def remote_send(socket, data):
    try:
        socket.send_string(data)
        msg = socket.recv_string()
        return msg
    except zmq.Again as e:
        print('Waiting for PUSH from MetaTrader5')



def main():
    global data

    context = zmq.Context()

    req_socket = context.socket(zmq.REQ)
    req_socket.connect("tcp://localhost:5555")

    session_options = blpapi.SessionOptions()
    session_options.setServerHost(d_host)
    session_options.setServerPort(d_port)

    event_handler = SessionEventHandler()

    print(f'Connection to {d_host}:{d_port}')

    session = blpapi.Session(session_options, event_handler.process_event)

    while context:

        msg = remote_send(req_socket, "TRADE|OPEN|0|WINV21|0|100|100|Python-to-MT5|100|12345678|0")

        data = msg.split('|')

        print(data)

        if not session.startAsync():
            print('Failed to start Async session')
            break

        global b_end
        while b_end == False:
            pass

        sleep(1)

    session.stop()


if __name__ == '__main__':
    print("Bloomber API with Socket")
    try:
        main()
    except KeyboardInterrupt:
        print("===============")
        print("CTRL+C pressed")
        print("===============")
