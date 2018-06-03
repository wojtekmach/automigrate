defmodule AutomigrateTest do
  use ExUnit.Case, async: true

  setup do
    File.rm_rf!("priv")
    TestRepo.query!("DROP TABLE IF EXISTS posts")
    :ok
  end

  test "automigrate" do
    assert Automigrate.diff(TestRepo, Post) == {:create_table, "posts", [id: :id, title: :string]}

    Automigrate.run(TestRepo, Post)

    assert Automigrate.diff(TestRepo, PostWithBody) == {:alter_table, "posts", add: [body: :string], remove: []}
  end
end
