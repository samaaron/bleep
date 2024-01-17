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
        [<<"uuid">>],
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
    {:ok, [res | _rest], _vm} = eval(vm, <<"return bleep_#{name}">>)
    res
  end

  def set_global(vm, name, value) do
    {:ok, _res, vm} = eval(vm, <<"bleep_#{name} = #{elixir_term_to_lua(value)}">>)
    vm
  end

  def elixir_term_to_lua(term) do
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
        "{ #{Enum.join(Enum.map(term, &elixir_term_to_lua/1), ", ")} }"

      _ ->
        inspect(term)
    end
  end
end
