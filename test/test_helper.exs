defmodule Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
  end
end

defmodule PostWithBody do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :body, :string
  end
end

defmodule TestRepo do
  use Ecto.Repo,
    otp_app: :automigrate,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    config =
      config
      |> Keyword.put_new(:url, "ecto://postgres:postgres@localhost/automigrate_test")
      # |> Keyword.put_new(:priv, "tmp")

    {:ok, config}
  end
end

ExUnit.start()
Mix.Ecto.ensure_repo(TestRepo, [])
Mix.Ecto.ensure_started(TestRepo, [])
