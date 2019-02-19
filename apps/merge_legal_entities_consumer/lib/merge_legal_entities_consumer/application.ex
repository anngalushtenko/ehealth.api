defmodule MergeLegalEntitiesConsumer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Kaffe.GroupMemberSupervisor,
        start: {Kaffe.GroupMemberSupervisor, :start_link, []},
        type: :supervisor
      }
    ]

    opts = [strategy: :one_for_one, name: MergeLegalEntitiesConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
