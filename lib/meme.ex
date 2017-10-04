defmodule Meme do

  #
  # public macro to use instead of def
  #

  defmacro defmemo(f_head = {:when, _, [{f_name, _, f_args} | _]}, [timeout: timeout], [do: body]) do
    quote do
      def unquote(f_head) do
        unquote(meme_under_the_hood(f_name, f_args, timeout, body))
      end
    end
  end
  defmacro defmemo(f_head = {f_name, _, f_args}, [timeout: timeout], [do: body]) do
    quote do
      def unquote(f_head) do
        unquote(meme_under_the_hood(f_name, f_args, timeout, body))
      end
    end
  end

  #
  # public macro to use instead of defp
  #

  defmacro defmemop(f_head = {:when, _, [{f_name, _, f_args} | _]}, [timeout: timeout], [do: body]) do
    quote do
      defp unquote(f_head) do
        unquote(meme_under_the_hood(f_name, f_args, timeout, body))
      end
    end
  end
  defmacro defmemop(f_head = {f_name, _, f_args}, [timeout: timeout], [do: body]) do
    quote do
      defp unquote(f_head) do
        unquote(meme_under_the_hood(f_name, f_args, timeout, body))
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

  defp meme_under_the_hood(f_name, f_args, timeout, code) do
    quote do
      (
        key = {__MODULE__, unquote(f_name), unquote(f_args)}
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

end
