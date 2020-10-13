defmodule WSServer.Application do
  use Application

  def start(_type, _args) do
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      # supervisor for tasks serving connections
      {Task.Supervisor, name: WSServer.TaskSupervisor},
      # supervisor for task responsible for accepting connections
      Supervisor.child_spec({Task, fn -> WSServer.accept(port) end}, restart: :permanent)
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WSServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
