defmodule Meme do

  #
  # public macro to use instead of def
  #

  defmacro defmemo(def_ast, [timeout: timeout], [do: body]) do
    quote do
      defmemo(unquote(def_ast), [timeout: unquote(timeout), condition: fn(_) -> true end], [do: unquote(body)])
    end
  end

  defmacro defmemo({:when, when_meta, [{name, meta, raw_args} | guards]}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      def unquote({:when, when_meta, [{name, meta, decorated_args} | guards]}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body, condition))
      end
    end
  end

  defmacro defmemo({name, meta, raw_args}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      def unquote({name, meta, decorated_args}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body, condition))
      end
    end
  end

  #
  # public macro - creates cached copy of function
  # if function name is :foo then two functions will be generated
  # :foo and :cached_foo (arity, arguments and business logic is the same)
  #

  defmacro defcached(def_ast, [timeout: timeout], [do: body]) do
    quote do
      defcached(unquote(def_ast), [timeout: unquote(timeout), condition: fn(_) -> true end], [do: unquote(body)])
    end
  end

  defmacro defcached(raw_definition = {:when, when_meta, [{name, meta, raw_args} | guards]}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    cached_name = String.to_atom("cached_#{name}")
    quote do
      def unquote({:when, when_meta, [{cached_name, meta, decorated_args} | guards]}) do
        unquote(meme_under_the_hood(cached_name, arg_names, timeout, body, condition))
      end
      def unquote(raw_definition) do
        unquote(body)
      end
    end
  end

  defmacro defcached(raw_definition = {name, meta, raw_args}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    cached_name = String.to_atom("cached_#{name}")
    quote do
      def unquote({cached_name, meta, decorated_args}) do
        unquote(meme_under_the_hood(cached_name, arg_names, timeout, body, condition))
      end
      def unquote(raw_definition) do
        unquote(body)
      end
    end
  end


  #
  # public macro to use instead of defp
  #

  defmacro defmemop(def_ast, [timeout: timeout], [do: body]) do
    quote do
      defmemop(unquote(def_ast), [timeout: unquote(timeout), condition: fn(_) -> true end], [do: unquote(body)])
    end
  end

  defmacro defmemop({:when, when_meta, [{name, meta, raw_args} | guards]}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      defp unquote({:when, when_meta, [{name, meta, decorated_args} | guards]}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body, condition))
      end
    end
  end

  defmacro defmemop({name, meta, raw_args}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    quote do
      defp unquote({name, meta, decorated_args}) do
        unquote(meme_under_the_hood(name, arg_names, timeout, body, condition))
      end
    end
  end

  #
  # public macro - creates functions like defcached do, but private
  #

  defmacro defcachedp(def_ast, [timeout: timeout], [do: body]) do
    quote do
      defcachedp(unquote(def_ast), [timeout: unquote(timeout), condition: fn(_) -> true end], [do: unquote(body)])
    end
  end

  defmacro defcachedp(raw_definition = {:when, when_meta, [{name, meta, raw_args} | guards]}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    cached_name = String.to_atom("cached_#{name}")
    quote do
      defp unquote({:when, when_meta, [{cached_name, meta, decorated_args} | guards]}) do
        unquote(meme_under_the_hood(cached_name, arg_names, timeout, body, condition))
      end
      defp unquote(raw_definition) do
        unquote(body)
      end
    end
  end

  defmacro defcachedp(raw_definition = {name, meta, raw_args}, [timeout: timeout, condition: condition], [do: body]) do
    {arg_names, decorated_args} = decorate_args(raw_args)
    cached_name = String.to_atom("cached_#{name}")
    quote do
      defp unquote({cached_name, meta, decorated_args}) do
        unquote(meme_under_the_hood(cached_name, arg_names, timeout, body, condition))
      end
      defp unquote(raw_definition) do
        unquote(body)
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

  defp meme_under_the_hood(name, args, timeout, code, condition) do
    quote do
      (
        key = {__MODULE__, unquote(name), unquote(args)}
        case Cachex.get(:meme, key) do
          {:missing, nil} ->
            value = (unquote(code))
            (unquote(condition)).(value)
            |> case do
              true -> {:ok, true} = Cachex.set(:meme, key, value, [ttl: unquote(timeout)])
              false -> :ok
            end
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
