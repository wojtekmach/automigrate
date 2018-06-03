defmodule Automigrate do
  def run(repo, schemas) when is_list(schemas) do
    Enum.each(schemas, &run(repo, &1))
  end

  def run(repo, schema) when is_atom(schema) do
    Mix.Ecto.ensure_repo(repo, [])
    Mix.Ecto.ensure_started(repo, [])

    name = Automigration
    module = Module.concat([repo, Migrations, name])
    result = diff(repo, schema)

    if result != :noop do
      inner = migration(result)
      contents =
        Code.format_string!("""
        defmodule #{inspect(module)} do
          use Ecto.Migration

          #{inner}
        end
        """)

      [filename] = Mix.Tasks.Ecto.Gen.Migration.run(~w(-r #{inspect(repo)} automigration))
      File.write!(filename, contents)
    end

    # Mix.Task.run("ecto.migrations", ~w(-r TestRepo))

    migrate(repo)
  end

  def diff(repo, schema) when is_atom(schema) do
    schema_fields = get_schema_fields(schema)
    table_fields = get_table_fields(repo, schema)
    table = table(schema)

    if table_exists?(repo, table) do
      add = schema_fields -- table_fields
      remove = table_fields -- schema_fields

      if add != [] or remove != [] do
        {:alter_table, table, add: add, remove: remove}
      else
        :noop
      end
    else
      {:create_table, table, schema_fields}
    end
  end

  defp migrate(repo) do
    Ecto.Migrator.run(repo, :up, all: true, log_sql: true)
  end

  defp migration({:alter_table, table, add: add, remove: remove}) do
    if remove != [] do
      """
      def up() do
        alter table(:#{table}) do
          #{for {f, t} <- add, do: "add #{inspect(f)}, #{inspect(t)}\n"}
          #{for {f, _t} <- remove, do: "remove #{inspect(f)}\n"}
        end
      end

      def down() do
        alter table(:#{table}) do
          #{for {f, _t} <- add, do: "remove #{inspect(f)}\n"}
          #{for {f, t} <- remove, do: "add #{inspect(f)}, #{inspect(t)}\n"}
        end
      end
      """
    else
      """
      def up() do
        alter table(:#{table}) do
          #{for {f, t} <- add, do: "add #{inspect(f)}, #{inspect(t)}\n"}
        end
      end
      """
    end
  end

  defp migration({:create_table, table, fields}) do
    fields = Keyword.delete(fields, :id)

    """
    def up() do
      create table(:#{table}) do
        #{for {f, t} <- fields, do: "add #{inspect(f)}, #{inspect(t)}\n"}
      end
    end
    """
  end

  defp get_schema_fields(schema) do
    for field <- schema.__schema__(:fields) do
      type = schema.__schema__(:type, field)
      {field, schema_type(type)}
    end
  end

  defp get_table_fields(repo, schema) do
    table = schema.__schema__(:source)
    result = get_columns(repo, table)

    for row <- Enum.map(result.rows, &Enum.into(Enum.zip(result.columns, &1), %{})) do
      column_name = String.to_atom(row["column_name"])

      if column_name == :id do
        {:id, :id}
      else
        {column_name, db_type(row["data_type"])}
      end
    end
  end

  defp table_exists?(repo, table) do
    sql = """
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables WHERE table_schema = $1 AND table_name = $2
    )
    """

    repo.query!(sql, ["public", table]).rows == [[true]]
  end

  defp get_columns(repo, table) do
    sql = "SELECT * FROM information_schema.columns WHERE table_schema = $1 AND table_name = $2"
    repo.query!(sql, ["public", table])
  end

  defp schema_type({:embed, _}), do: :map
  defp schema_type(other), do: other

  defp db_type("integer"), do: :integer
  defp db_type("character varying"), do: :string
  defp db_type("date"), do: :date
  defp db_type("jsonb"), do: :map

  defp table(schema), do: schema.__schema__(:source)
end
