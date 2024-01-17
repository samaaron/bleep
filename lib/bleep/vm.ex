defmodule Bleep.VM do
  @moduledoc """
  The VM module is responsible for creating and managing the Lua VM.
  """

  def eval(code, vm) do
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
end
