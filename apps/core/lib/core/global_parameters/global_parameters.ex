defmodule Core.GlobalParameters do
  @moduledoc """
  The boundary for the Global parameters system.
  """

  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Core.GlobalParameters.GlobalParameter
  alias Core.PRMRepo

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @fields_required ~w(
    parameter
    value
    inserted_by
    updated_by
  )a

  def list do
    query = from(gp in GlobalParameter, order_by: [desc: :inserted_at])
    @read_prm_repo.all(query)
  end

  def create(attrs, user_id) do
    %GlobalParameter{}
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(user_id)
  end

  def update(%GlobalParameter{} = global_parameter, attrs, user_id) do
    global_parameter
    |> changeset(attrs)
    |> PRMRepo.update_and_log(user_id)
  end

  def get_values do
    for p <- list(), into: %{}, do: {p.parameter, p.value}
  end

  def create_or_update(params, client_id) do
    result =
      params
      |> Map.keys()
      |> Enum.reduce_while(nil, fn x, _acc -> process(x, params, client_id) end)

    case result do
      nil -> {:ok, list()}
      error -> error
    end
  end

  defp create_or_update(key, value, client_id) do
    case @read_prm_repo.get_by(GlobalParameter, parameter: key) do
      %GlobalParameter{} = global_parameter ->
        update(
          global_parameter,
          %{
            value: value,
            updated_by: client_id
          },
          client_id
        )

      nil ->
        create(
          %{
            parameter: key,
            value: value,
            inserted_by: client_id,
            updated_by: client_id
          },
          client_id
        )
    end
  end

  defp process(x, params, client_id) do
    case create_or_update(x, Map.get(params, x), client_id) do
      {:ok, _} -> {:cont, nil}
      {:error, _} = error -> {:halt, error}
    end
  end

  defp changeset(%GlobalParameter{} = global_parameter, attrs) do
    global_parameter
    |> cast(attrs, @fields_required)
    |> validate_required(@fields_required)
  end
end
