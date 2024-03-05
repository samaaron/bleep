defmodule Bleep.VM do
  @moduledoc """
  The VM module is responsible for creating and managing the Lua VM.
  """

  def eval(vm, code) do
    :luerl_new.do_dec(code, vm)
  end

  def make_vm(seed_code) do
    vm = :luerl_sandbox.init()

    vm =
      :luerl.set_table(
        [<<"__bleep_vm_uuid">>],
        fn _args, state ->
          {[UUID.uuid4()], state}
        end,
        vm
      )

    {_, vm} =
      :luerl.do(
        seed_code,
        vm
      )

    vm
  end

  def add_fn(vm, name, fun) do
    :luerl.set_table(
      [name],
      fn args, state ->
        {[fun.(state, args)], state}
      end,
      vm
    )
  end

  def get_global(vm, name) do
    {:ok, [res | _rest], _vm} = eval(vm, <<"return #{name}">>)
    res
  end

  def set_global(vm, name, value) do
    {:ok, _res, vm} = eval(vm, <<"#{name} = #{elixir_term_to_lua(value)}">>)
    vm
  end

  def lua_table_to_map(table) do
    Enum.reduce(table, %{}, fn
      {k, v}, acc when is_binary(k) ->
        Map.put(acc, String.to_atom(k), v)

      {k, v}, acc ->
        Map.put(acc, k, v)
    end)
  end

  def lua_table_array_to_list(table) do
    map = lua_table_to_map(table)
    array_map_to_list(map)
  end

  defp array_map_to_list(map, index \\ 1) do
    case Map.has_key?(map, index) do
      true ->
        [Map.get(map, index) | array_map_to_list(map, index + 1)]

      false ->
        []
    end
  end

  defp elixir_term_to_lua(term) do
    case term do
      nil ->
        "nil"

      true ->
        "true"

      false ->
        "false"

      _ when is_number(term) ->
        "#{term}"

      _ when is_binary(term) ->
        "\"#{term}\""

      _ when is_list(term) ->
        "{ #{Enum.map_join(term, ", ", &elixir_term_to_lua/1)} }"

      _ ->
        inspect(term)
    end
  end
end
