defmodule WS.Client.Application do
  use Application

  def start(_type, port) do
    children = [
      # supervisor for tasks opening connections
      {Task.Supervisor, name: WS.Client.TaskSupervisor},
      # supervisor for task responsible for opening connection
      Supervisor.child_spec({Task, fn -> WS.Client.connect(port) end}, restart: :temporary)
    ]

    opts = [strategy: :one_for_one, name: WS.Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
