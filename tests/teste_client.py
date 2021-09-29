import socket

client_socket = socket.socket()

host = "localhost"
port= 5555

try:
    client_socket.connect((host, port))
except socket.error as e:
    print(str(e))

while True:
    message = "Other client"
    client_socket.sendall(message.encode("utf-8"))

    message_respose = client_socket.recv(2048)
    print("voltou a message")
    

