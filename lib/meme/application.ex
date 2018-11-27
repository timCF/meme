defmodule Meme.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Meme.Worker.start_link(arg1, arg2, arg3)
      # worker(Meme.Worker, [arg1, arg2, arg3]),
      worker(Cachex, [:meme, [], []], [id: :meme])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Meme.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
