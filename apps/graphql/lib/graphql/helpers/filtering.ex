defmodule GraphQL.Helpers.Filtering do
  @moduledoc false

  import Ecto.Query, only: [join: 4, where: 3]

  def filter(query, []), do: query

  def filter(query, [{field, rule, value} | tail]) do
    # TODO: generalize field introspection
    type = introspect(query, field)

    filter(query, [{type, field, rule, value} | tail])
  end

  def filter(query, [{_type, field, :equal, value} | tail]) do
    query
    |> where([..., r], field(r, ^field) == ^value)
    |> filter(tail)
  end

  def filter(query, [{_type, field, :not_equal, value} | tail]) do
    query
    |> where([..., r], field(r, ^field) != ^value)
    |> filter(tail)
  end

  def filter(query, [{_type, field, :less_than_or_equal, value} | tail]) do
    query
    |> where([..., r], field(r, ^field) <= ^value)
    |> filter(tail)
  end

  def filter(query, [{_type, field, :greater_than_or_equal, value} | tail]) do
    query
    |> where([..., r], field(r, ^field) >= ^value)
    |> filter(tail)
  end

  def filter(query, [{_type, field, :less_than, value} | tail]) do
    query
    |> where([..., r], field(r, ^field) < ^value)
    |> filter(tail)
  end

  def filter(query, [{_type, field, :greater_than, value} | tail]) do
    query
    |> where([..., r], field(r, ^field) > ^value)
    |> filter(tail)
  end

  # TODO: Add sanitization for value in order to prevent [LIKE-injections](https://githubengineering.com/like-injection/).
  def filter(query, [{_type, field, :like, value} | tail]) do
    query
    |> where([..., r], ilike(field(r, ^field), ^"%#{value}%"))
    |> filter(tail)
  end

  def filter(query, [{_, field, :in, value} | tail]) when is_list(value) do
    query
    |> where([..., r], field(r, ^field) in ^value)
    |> filter(tail)
  end

  def filter(query, [{:date, field, :in, %Date.Interval{first: %Date{} = first, last: %Date{} = last}} | tail]) do
    query
    |> where([..., r], fragment("? <@ daterange(?, ?, '[]')", field(r, ^field), ^first, ^last))
    |> filter(tail)
  end

  def filter(query, [{:date, field, :in, %Date.Interval{first: %Date{} = first}} | tail]) do
    query
    |> where([..., r], fragment("? <@ daterange(?, 'infinity', '[)')", field(r, ^field), ^first))
    |> filter(tail)
  end

  def filter(query, [{:date, field, :in, %Date.Interval{last: %Date{} = last}} | tail]) do
    query
    |> where([..., r], fragment("? <@ daterange('infinity', ?, '(]')", field(r, ^field), ^last))
    |> filter(tail)
  end

  def filter(query, [{{:array, _}, field, :contains, value} | tail]) do
    query
    |> where([..., r], fragment("? @> ?", field(r, ^field), ^value))
    |> filter(tail)
  end

  # TODO: implement filtering on rest conditions
  def filter(query, [{{:array, :map}, field, nil, conditions} | tail]) when is_list(conditions) do
    conditions =
      conditions
      |> Enum.map(fn
        {field, :equal, value} -> {field, value}
        {_, _, _} -> raise "Only :equal condition on {:array, :map} fields allowed"
      end)
      |> Map.new()
      |> List.wrap()

    query
    |> where([..., r], fragment("? @> ?", field(r, ^field), ^conditions))
    |> filter(tail)
  end

  def filter(query, [{%{cardinality: :one, related: related}, field, nil, conditions} | tail]) do
    conditions =
      for {field, rule, value} <- conditions do
        # TODO: generalize field introspection
        type = introspect(related, field)
        {type, field, rule, value}
      end

    query
    |> filter(tail)
    |> join(:inner, [r], assoc(r, ^field))
    |> filter(conditions)
  end

  defp introspect(queryable, field) do
    %{from: {_, queryable}} = Ecto.Queryable.to_query(queryable)

    Enum.reduce_while(
      ~w(association embed type)a,
      nil,
      fn type, _ ->
        if type = queryable.__schema__(type, field), do: {:halt, type}, else: {:cont, nil}
      end
    )
  end
end
