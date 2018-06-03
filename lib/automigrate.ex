defmodule Automigrate do
  def diff(repo, schema) when is_atom(schema) do
    schema_fields = get_schema_fields(schema)
    table_fields = get_table_fields(repo, schema)
    table = table(schema)

    if table_exists?(repo, table) do
      added = schema_fields -- table_fields
      removed = table_fields -- schema_fields

      if added != [] or removed != [] do
        {:alter_table, table, added: added, removed: removed}
      else
        :noop
      end
    else
      {:create_table, table, schema_fields}
    end
  end

  ## Private

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
      {String.to_atom(row["column_name"]), db_type(row["data_type"])}
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

  defp db_type("integer"), do: :id
  defp db_type("text"), do: :string
  defp db_type("character varying"), do: :string
  defp db_type("date"), do: :date
  defp db_type("jsonb"), do: :map

  defp table(schema), do: schema.__schema__(:source)
end
