defmodule WS.Server.Application do
  use Application

  def start(_type, port) do


    children = [
      # supervisor for tasks serving connections
      {Task.Supervisor, name: WS.Server.TaskSupervisor},
      # supervisor for register mapping channelectories to processes
      Supervisor.child_spec({Task, fn -> WS.Server.Register.start() end}, id: {Task, 0}),
      # supervisor for task responsible for accepting connections
      Supervisor.child_spec({Task, fn -> WS.Server.accept(port) end}, id: {Task, 1}),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html for more
    opts = [strategy: :one_for_one, name: WS.Server.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
