# WS
### A simple websocket server and client implementation

**TODO: Add description**

## Installation
install Elixir 1.10 or newer

## Run
Using port 4040
Start app:```$ iex -S mix```
Run server app: ```iex> WS.Server.Application.start(0, 4040)```
Start client supervisor: ```iex> WS.Client.Application.start(0, 4040)```
Start client: ```iex> WS.Client.connect(4040)```
