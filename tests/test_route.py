import blpapi

SESSION_STARTED = blpapi.Name('SessionStarted')
SESSION_STARTUP_FAILURE = blpapi.Name('SessionStartupFailure')
CREATE_ORDER_AND_ROUTE_EX = blpapi.Name('CreateOrderAndRouteEx')

d_emsx_service = '//blp/emapisvc_beta'
d_host = '127.0.0.1'
d_port = 8194
b_end = False

class SessionEventHandler():
    
    def process_event(self, event, session):

        try:
            if event.eventType() == blpapi.Event.SESSION_STATUS:
                self.processSessionStatusEvent(event, session)

            elif event.eventType() == blpapi.Event.SERVICE_STATUS:
                self.processServiceStatusEvent(event)

            elif event.eventType() == blpapi.Event.RESPONSE:
                self.processResponseEvent(event)

            else:
                self.processMiscEvents(event)

        except:
            print(f'Exception: {sys.exc_info()[0]}')

        return False


    def process_session_status_event(self, event, session):
        print('Processing SESSION_STATUS event')

        global d_emsx_service

        for msg in event:
            if msg.messageType() == SESSION_STARTED:
                print('Session started....')
                session.openServiceAsync(d_emsx_service)

            elif msg.messageType() == SESSION_STARTUP_FAILURE:
                print(f'Error: Session startup failure {sys.stderr}')
            
            else:
                print(msg)

    def process_service_status_event(self, event, session):
        global data
        
        print('Processing SERVICE_STATUS event')

        for msg in event:
            if msg.messageType() == SERVICE_OPENED:
                print('Service opened....')

                service = session.getService(d_emsx_service)

                request = service.createRequest("CreateAndRouteEx")

                symbol = ''

                print(data)

                if data[0].contains('WIN'):
                    symbol = 'XBV1 Index'
                else:
                    symbol = data[0] + 'Bz Equity'

                if data[3] == 0:
                    order_side = 'BUY'
                elif data[3] == 1:
                    order_side = 'SELL'

                request.set("EMSX_TICKER", symbol)
                request.set("EMSX_AMOUNT", data[1])
                request.set("EMSX_ORDER_TYPE", data[2])
                request.set("EMSX_SIDE", order_side)
                request.set("EMSX_TIF", data[4])
                request.set("EMSX_HAND_INSTRUCTION", "ANY")
                

                print(f'Request: {request.toString()}')

                self.request_ID = blpapi.CorrelationId()

                session.sendRequest(request, correlationId=self.request_ID)

            elif msg.messageType() == SERVICE_OPEN_FAILURE:
                print(f'Error: service failed to open {sys.stderr}')