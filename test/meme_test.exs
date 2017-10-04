defmodule MemeTest do
  use ExUnit.Case
  import Meme
  doctest Meme

  @ttl 1000
  @randlimit 6000000000

  test "memo" do
    result = Meme.memo(:rand, :uniform, [@randlimit], @ttl)
    assert result == Meme.memo(:rand, :uniform, [@randlimit], @ttl)
    _ = :timer.sleep(@ttl * 2)
    assert result != Meme.memo(:rand, :uniform, [@randlimit], @ttl)
  end

  defmemo rand_public(limit), timeout: @ttl do
    :rand.uniform(limit)
  end
  test "defmemo" do
    result = __MODULE__.rand_public(@randlimit)
    assert result == __MODULE__.rand_public(@randlimit)
    _ = :timer.sleep(@ttl * 2)
    assert result != __MODULE__.rand_public(@randlimit)
  end

  defmemo rand_public_when(limit) when (is_integer(limit) and (limit > 0)), timeout: @ttl do
    :rand.uniform(limit)
  end
  test "defmemo + when" do
    result = __MODULE__.rand_public_when(@randlimit)
    assert result == __MODULE__.rand_public_when(@randlimit)
    _ = :timer.sleep(@ttl * 2)
    assert result != __MODULE__.rand_public_when(@randlimit)
  end

  defpmemo rand_private(limit), timeout: @ttl do
    :rand.uniform(limit)
  end
  test "defpmemo generates private function" do
    assert false == :erlang.function_exported(__MODULE__, :rand_private, 1)
  end
  test "defpmemo" do
    result = rand_private(@randlimit)
    assert result == rand_private(@randlimit)
    _ = :timer.sleep(@ttl * 2)
    assert result != rand_private(@randlimit)
  end

  defpmemo rand_private_when(limit) when (is_integer(limit) and (limit > 0)), timeout: @ttl do
    :rand.uniform(limit)
  end
  test "defpmemo + when generates private function" do
    assert false == :erlang.function_exported(__MODULE__, :rand_private_when, 1)
  end
  test "defpmemo + when" do
    result = rand_private_when(@randlimit)
    assert result == rand_private_when(@randlimit)
    _ = :timer.sleep(@ttl * 2)
    assert result != rand_private_when(@randlimit)
  end

end
