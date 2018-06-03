defmodule AutomigrateTest do
  use ExUnit.Case, async: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    :ok
  end

  test "automigrate" do
    assert Automigrate.diff(TestRepo, Post) == {:create_table, "posts", [id: :id, title: :string]}
  end
end
