defmodule Meme.CompiletimeConfig do
  @permanent_key :permanent
  @timeout_key :timeout
  @condition_key :condition

  defstruct [
    {@permanent_key, false},
    {@timeout_key, nil},
    {@condition_key, nil}
  ]

  @type t() :: %__MODULE__{
          permanent: boolean(),
          timeout: nil | pos_integer | {atom(), any(), any()},
          condition: nil | {:fn, any(), any()} | {:&, any(), any()}
        }

  @doc """
  Creates and validates new #{__MODULE__}.t()
  Can raise exception if given params are incorrect
  """
  @spec new!(Keyword.t()) :: t() | no_return()
  def new!(kv) when is_list(kv) do
    kv
    |> Keyword.keyword?()
    |> case do
      true ->
        kv
        |> Enum.uniq()
        |> case do
          ^kv ->
            kv
            |> Enum.reduce(%__MODULE__{}, fn
              # permanent :: boolean
              {@permanent_key, no = false}, acc = %__MODULE__{} ->
                Map.replace!(acc, @permanent_key, no)

              {@permanent_key, yes = true}, acc = %__MODULE__{} ->
                Map.replace!(acc, @permanent_key, yes)

              # timeout :: nil | pos_integer | AST (expression)
              {@timeout_key, no = nil}, acc = %__MODULE__{} ->
                Map.replace!(acc, @timeout_key, no)

              {@timeout_key, ttl}, acc = %__MODULE__{} when is_integer(ttl) and ttl > 0 ->
                Map.replace!(acc, @timeout_key, ttl)

              {@timeout_key, ttl = {ast, _, _}}, acc = %__MODULE__{} when is_atom(ast) ->
                Map.replace!(acc, @timeout_key, ttl)

              # condition :: nil | AST (function arity 1)
              {@condition_key, no = nil}, acc = %__MODULE__{} ->
                Map.replace!(acc, @condition_key, no)

              {@condition_key, condition = {ast, _, _}}, acc = %__MODULE__{}
              when ast in [:fn, :&] ->
                Map.replace!(acc, @condition_key, condition)

              # otherwise raise
              {k, v}, %__MODULE__{} ->
                raise("wrong config key-value pair #{inspect(k)} => #{inspect(v)}")
            end)
            |> validate!

          _ ->
            raise("config has repeating keys #{inspect(kv)}")
        end

      false ->
        raise("wrong config #{inspect(kv)}")
    end
  end

  defp validate!(config = %__MODULE__{permanent: true, timeout: nil}) do
    config
  end

  defp validate!(config = %__MODULE__{permanent: false, timeout: ttl}) when ttl != nil do
    config
  end

  defp validate!(config = %__MODULE__{}) do
    raise("incompatible parameters in config #{inspect(config)}")
  end
end
