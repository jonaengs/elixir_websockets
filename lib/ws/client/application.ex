defmodule WS.Client.Application do
  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      # supervisor for tasks opening connections
      {Task.Supervisor, name: WS.Client.TaskSupervisor},
      # supervisor for task responsible for opening connection
      Supervisor.child_spec({Task, fn -> WS.Client.connect("localhost", port) end}, restart: :temporary)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html for more
    opts = [strategy: :one_for_one, name: WS.Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
