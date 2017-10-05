defmodule Meme do

  #
  # public macro to use instead of def
  #

  defmacro defmemo({:when, when_meta, [{name, meta, raw_args} | guards]}, [timeout: timeout], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      def unquote({:when, when_meta, [{name, meta, decorated_args} | guards]}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body))
      end
    end
  end
  defmacro defmemo({name, meta, raw_args}, [timeout: timeout], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      def unquote({name, meta, decorated_args}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body))
      end
    end
  end

  #
  # public macro to use instead of defp
  #

  defmacro defmemop({:when, when_meta, [{name, meta, raw_args} | guards]}, [timeout: timeout], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      defp unquote({:when, when_meta, [{name, meta, decorated_args} | guards]}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body))
      end
    end
  end
  defmacro defmemop({name, meta, raw_args}, [timeout: timeout], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      defp unquote({name, meta, decorated_args}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body))
      end
    end
  end

  #
  # simple public function for MFA usage
  #

  def memo(module, func, args, ttl) when (is_atom(module) and is_atom(func) and is_list(args) and is_integer(ttl) and (ttl > 0)) do
    key = {module, func, args}
    case Cachex.get(:meme, key) do
      {:missing, nil} ->
        value = :erlang.apply(module, func, args)
        {:ok, true} = Cachex.set(:meme, key, value, [ttl: ttl])
        value
      {:ok, value} ->
        value
    end
  end

  #
  # priv boilerplate for defmemo / defmemop macro
  #

  defp meme_under_the_hood(name, args, timeout, code) do
    quote do
      (
        key = {__MODULE__, unquote(name), unquote(args)}
        case Cachex.get(:meme, key) do
          {:missing, nil} ->
            value = (unquote(code))
            {:ok, true} = Cachex.set(:meme, key, value, [ttl: unquote(timeout)])
            value
          {:ok, value} ->
            value
        end
      )
    end
  end

  defp decorate_args(raw_args) when is_list(raw_args) do
    raw_args
    |> Stream.with_index
    |> Stream.map(fn({arg_ast, index}) ->
      arg_name = Macro.var(:"arg#{index}", __MODULE__)
      {
        arg_name,
        quote do
          unquote(arg_ast) = unquote(arg_name)
        end
      }
    end)
    |> Enum.unzip
  end

end
