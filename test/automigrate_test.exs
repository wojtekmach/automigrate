defmodule AutomigrateTest do
  use ExUnit.Case, async: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    :ok
  end

  test "sanity" do
  end
end
