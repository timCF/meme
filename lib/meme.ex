defmodule Meme do

  #
  # public macro to use instead of def
  #

  defmacro defmemo(f_head = {:when, _, [{f_name, _, f_args} | _]}, [timeout: timeout], [do: body]) do
    quote do
      def unquote(f_head) do
        {
          __MODULE__,
          unquote(f_name),
          unquote(f_args)
        }
        |> meme_under_the_hood(unquote(timeout), unquote(body))
      end
    end
  end
  defmacro defmemo(f_head = {f_name, _, f_args}, [timeout: timeout], [do: body]) do
    quote do
      def unquote(f_head) do
        {
          __MODULE__,
          unquote(f_name),
          unquote(f_args)
        }
        |> meme_under_the_hood(unquote(timeout), unquote(body))
      end
    end
  end

  #
  # public macro to use instead of defp
  #

  defmacro defpmemo(f_head = {:when, _, [{f_name, _, f_args} | _]}, [timeout: timeout], [do: body]) do
    quote do
      defp unquote(f_head) do
        {
          __MODULE__,
          unquote(f_name),
          unquote(f_args)
        }
        |> meme_under_the_hood(unquote(timeout), unquote(body))
      end
    end
  end
  defmacro defpmemo(f_head = {f_name, _, f_args}, [timeout: timeout], [do: body]) do
    quote do
      defp unquote(f_head) do
        {
          __MODULE__,
          unquote(f_name),
          unquote(f_args)
        }
        |> meme_under_the_hood(unquote(timeout), unquote(body))
      end
    end
  end

  #
  # it's public only for defmemo / defpmemo macro
  #

  defmacro meme_under_the_hood(key, timeout, code) do
    quote do
      case Cachex.get(:meme, unquote(key)) do
        {:missing, nil} ->
          value = (unquote(code))
          {:ok, true} = Cachex.set(:meme, unquote(key), value, [ttl: unquote(timeout)])
          value
        {:ok, value} ->
          value
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

end
