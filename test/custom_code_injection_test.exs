defmodule CustomCodeClient do
  use BamlElixir.Client,
    path: "test/baml_src",
    inject_code: (
      def custom_greeting, do: "Hello from #{__MODULE__}"
    )
end

defmodule CustomCodeInjectionTest do
  use ExUnit.Case

  @tag :custom_code
  test "custom function defined in do block is callable on generated class modules" do
    assert CustomCodeClient.Person.custom_greeting() =~ "CustomCodeClient.Person"
  end

  @tag :custom_code
  test "__MODULE__ in the block resolves to the generated class module name" do
    assert CustomCodeClient.Person.custom_greeting() == "Hello from Elixir.CustomCodeClient.Person"
    assert CustomCodeClient.Attendees.custom_greeting() == "Hello from Elixir.CustomCodeClient.Attendees"
  end

  @tag :custom_code
  test "existing behavior (no do block) still works" do
    # TypeCoercionClient (defined in type_coercion_test.exs) uses no do block
    # and should still compile. We also verify struct creation works.
    person = TypeCoercionClient.Person.__struct__()
    assert person.name == nil
    assert person.age == nil
  end
end
