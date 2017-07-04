defmodule MemeTest do
  use ExUnit.Case
  doctest Meme

  test "memo" do
    ttl = 1000
    arg1 = 6000000000
    result = Meme.memo(:rand, :uniform, [arg1], ttl)
    assert result == Meme.memo(:rand, :uniform, [arg1], ttl)
    _ = :timer.sleep(ttl * 2)
    assert result != Meme.memo(:rand, :uniform, [arg1], ttl)
  end
end
