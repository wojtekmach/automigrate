defmodule Post1 do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :foo, :integer
  end
end

defmodule Post2 do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :bar, :string
  end
end

defmodule AutomigrateTest do
  use ExUnit.Case, async: true

  setup do
    File.rm_rf!("priv")
    TestRepo.query!("DROP TABLE IF EXISTS posts")
    :ok
  end

  test "automigrate" do
    assert Automigrate.diff(TestRepo, Post1) == {:create_table, "posts", [id: :id, title: :string, foo: :integer]}

    Automigrate.run(TestRepo, Post1)
    assert Automigrate.diff(TestRepo, Post1) == :noop
    assert Automigrate.diff(TestRepo, Post2) == {:alter_table, "posts", add: [bar: :string], remove: [foo: :integer]}
  end
end
