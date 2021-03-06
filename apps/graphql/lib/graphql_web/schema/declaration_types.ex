defmodule GraphQLWeb.Schema.DeclarationTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1, dataloader: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias GraphQLWeb.Loaders.{MPI, PRM}
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.DeclarationResolver

  object :declaration_queries do
    @desc "Get all declarations"
    connection field(:pending_declarations, node_type: :declaration) do
      meta(:scope, ~w(declaration:read))
      arg(:filter, :pending_declaration_filter)
      arg(:order_by, :declaration_order_by)

      middleware(Filtering, reason: :equal)

      resolve(&DeclarationResolver.list_pending_declarations/2)
    end

    @desc "Get declaration by id"
    field(:declaration, :declaration) do
      meta(:scope, ~w(declaration:read))
      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :declaration)
      resolve(&DeclarationResolver.get_declaration_by_id/3)
    end

    @desc "Get declaration by its unique number"
    field(:declaration_by_number, :declaration) do
      meta(:scope, ~w(declaration:read))
      arg(:declaration_number, non_null(:string))

      resolve(&DeclarationResolver.get_declaration_by_number/3)
    end
  end

  object :declaration_mutations do
    payload field(:approve_declaration) do
      meta(:scope, ~w(declaration:approve))
      meta(:client_metadata, ~w(client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
      end

      output do
        field(:declaration, :declaration)
      end

      middleware(ParseIDs, id: :declaration)
      resolve(&DeclarationResolver.approve_declaration/2)
    end

    payload field(:reject_declaration) do
      meta(:scope, ~w(declaration:reject))
      meta(:client_metadata, ~w(client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
      end

      output do
        field(:declaration, :declaration)
      end

      middleware(ParseIDs, id: :declaration)
      resolve(&DeclarationResolver.reject_declaration/2)
    end

    payload field(:terminate_declaration) do
      meta(:scope, ~w(declaration:terminate))
      meta(:client_metadata, ~w(client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
        field(:reason_description, :string)
      end

      output do
        field(:declaration, :declaration)
      end

      middleware(ParseIDs, id: :declaration)
      resolve(&DeclarationResolver.terminate_declaration/2)
    end
  end

  input_object :pending_declaration_filter do
    field(:reason, :pending_declaration_reason)
  end

  enum :pending_declaration_reason do
    value(:no_tax_id, as: "no_tax_id")
  end

  enum :declaration_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:reason_asc)
    value(:reason_desc)
    value(:start_date_asc)
    value(:start_date_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection node_type: :declaration do
    field :nodes, list_of(:declaration) do
      resolve(fn
        _, %{source: conn} ->
          nodes = conn.edges |> Enum.map(& &1.node)
          {:ok, nodes}
      end)
    end

    edge(do: nil)
  end

  node object(:declaration) do
    field(:database_id, non_null(:uuid))
    field(:declaration_number, non_null(:string))
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
    field(:signed_at, non_null(:datetime))
    field(:status, non_null(:declaration_status))
    field(:scope, non_null(:string))
    field(:reason, :string)
    field(:reason_description, :string)
    field(:legal_entity, non_null(:legal_entity), resolve: dataloader(PRM))
    field(:division, non_null(:division), resolve: dataloader(PRM))
    field(:employee, non_null(:employee), resolve: dataloader(PRM))
    field(:person, non_null(:person), resolve: dataloader(MPI, {:search_persons, :one, :person_id, :id}))

    field :declaration_attached_documents, list_of(:declaration_attached_document) do
      meta(:scope, ~w(declaration_documents:read))
      resolve(&DeclarationResolver.resolve_attached_documents/3)
    end
  end

  enum :declaration_status do
    value(:active, as: "active")
    value(:pending_verification, as: "pending_verification")
    value(:rejected, as: "rejected")
    value(:terminated, as: "terminated")
    value(:closed, as: "closed")
  end

  object :declaration_attached_document do
    field(:type, non_null(:string))
    field(:url, non_null(:string))
  end
end
