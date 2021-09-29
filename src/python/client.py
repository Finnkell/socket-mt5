import threading
from random import Random, choice, randint

import zmq
import time

letters = ['LETTERA', 'LETTERB', 'LETTERC', 'LETTERD', 'LETTERF', 'LETTERG']
letra = choice(letters)

class Client(threading.Thread):
    ''' Represents an example client. '''
    def __init__(self, identity):
        threading.Thread.__init__(self)
        self.identity = identity
        self.zmq_context = zmq.Context()

    def run(self):
        ''' Connects to server. Send compute request, poll for and print result to standard out. '''
        num1, num2 = self.generate_numbers()
        print('Client ID - %s. Numbers to be added - %s and %s.' % (self.identity, num1, num2))
        socket = self.get_connection()
        
        # Poller is used to check for availability of data before reading from a socket.
        poller = zmq.Poller()
        poller.register(socket, zmq.POLLIN)

        send_message = "TRADE|OPEN|99999|PETR3|1.0|MKT|DAY|BUY"
        self.send(socket, send_message)

        # Infinitely poll for the result. 
        # Polling is used to check for sockets with data before reading because socket.recv() is blocking.

        while True:
            # Poll for 5 seconds. Return any sockets with data to be read.
            sockets = dict(poller.poll(5000))

            # If socket has data to be read.
            if socket in sockets and sockets[socket] == zmq.POLLIN:
                result = self.receive(socket)
                print('Client ID - %s. Numbers sent to be added - %s and %s. Received result - %s.' % (self.identity, num1, num2, result))
                break

        socket.close()
        self.zmq_context.term()

    def send(self, socket, data):
        ''' Send data through provided socket. '''

        data = str(data + "|" + letra)

        socket.send_string(data)

    def receive(self, socket):
        ''' Recieve and return data through provided socket. '''
        return socket.recv()

    def get_connection(self):
        ''' Create a zeromq socket of type DEALER; set it's identity, connect to server and return socket. '''

        # Socket type DEALER is used in asynchronous request/reply patterns.
        # It prepends identity of the socket with each message.
        socket = self.zmq_context.socket(zmq.DEALER)
        socket.setsockopt_string(zmq.IDENTITY, self.identity)
        socket.connect('tcp://127.0.0.1:5001')
        return socket

    def generate_numbers(self):
        ''' Generate and return a pair of numbers. '''
        number_list = range(0,10)
        num1 = choice(number_list)
        num2 = choice(number_list)
        return num1, num2

if __name__ == '__main__':
    # Instantiate three clients with different ID's.
    while True:
        print("====================================")
        for i in range(1, randint(3, 99)):
            client = Client(str(i))
            client.start()

        time.sleep(1.5)
