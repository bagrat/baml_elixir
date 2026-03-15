defmodule TypeCoercionClient do
  use BamlElixir.Client, path: "test/baml_src"
end

defmodule TypeCoercionTest do
  use ExUnit.Case

  import Mox

  setup :set_mox_from_context
  setup :verify_on_exit!

  defp call_extract_person(args) do
    BamlElixirTest.FakeOpenAIServer.expect_chat_completion(
      ~s|{"name": "Test", "age": 1}|
    )

    base_url = BamlElixirTest.FakeOpenAIServer.start_base_url()

    client_registry = %{
      primary: "InjectedClient",
      clients: [
        %{
          name: "InjectedClient",
          provider: "openai-generic",
          retry_policy: nil,
          options: %{
            base_url: base_url,
            api_key: "test-key",
            model: "gpt-4o-mini"
          }
        }
      ]
    }

    TypeCoercionClient.ExtractPerson.call(args, %{
      client_registry: client_registry,
      parse: false
    })
  end

  @tag :type_coercion
  test "atom values are coerced to strings" do
    assert {:ok, _} = call_extract_person(%{info: :hello})
  end

  @tag :type_coercion
  test "Date values are coerced to ISO 8601 strings" do
    assert {:ok, _} = call_extract_person(%{info: ~D[2024-01-15]})
  end

  @tag :type_coercion
  test "DateTime values are coerced to ISO 8601 strings" do
    assert {:ok, _} = call_extract_person(%{info: ~U[2024-01-15 10:30:00Z]})
  end

  @tag :type_coercion
  test "existing types (strings, numbers, maps, lists) still work" do
    assert {:ok, _} = call_extract_person(%{info: "hello"})
  end

  @tag :type_coercion
  test "tuple values are coerced to lists (not unsupported type error)" do
    # Tuples become lists; BAML will reject a list for a string param,
    # but the important thing is no "Unsupported type" NIF error.
    # Don't use the fake server since BAML rejects params before making HTTP call.
    {:error, msg} =
      BamlElixir.Client.call("ExtractPerson", %{info: {"hello", "world"}}, %{
        path: "test/baml_src",
        parse: false
      })

    refute msg =~ "Unsupported type"
    assert msg =~ "Invalid parameters"
  end

  @tag :type_coercion
  test "true, false, nil are not converted to strings" do
    # Booleans and nil should pass through to the NIF as-is.
    # BAML will reject them for a string param.
    # Don't use the fake server since BAML rejects params before making HTTP call.
    {:error, msg} =
      BamlElixir.Client.call("ExtractPerson", %{info: true}, %{
        path: "test/baml_src",
        parse: false
      })

    refute msg =~ "Unsupported type"
    assert msg =~ "Invalid parameters"
  end
end
