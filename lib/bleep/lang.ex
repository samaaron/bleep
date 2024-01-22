defmodule Bleep.Lang do
  @core_lua_path Path.join([:code.priv_dir(:bleep), "lua", "core.lua"])
  @core_lua File.read!(@core_lua_path)

  require Logger

  @moduledoc """
  This module is responsible for evaluating Lua code and sending the results

  """

  def lua_time(lua) do
    global_time_s = Bleep.VM.get_global(lua, "global_time")
    start_time_s = Bleep.VM.get_global(lua, "start_time")
    global_time_s + start_time_s
  end

  def __bleep_ex_start_fx(lua, [uuid, fx_id]) do
    __bleep_ex_start_fx(lua, [uuid, fx_id, []])
  end

  def __bleep_ex_start_fx(lua, [uuid, fx_id, opts_table]) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)

    tag = "*"

    broadcast({time_s, tag, {:core_start_fx, uuid, fx_id, output_id, opts}})
  end

  def __bleep_ex_stop_fx(lua, [uuid]) do
    time_s = lua_time(lua)
    opts = %{}
    tag = "*"

    broadcast({time_s, tag, {:core_stop_fx, uuid, opts}})
  end

  def __bleep_ex_sample(lua, [sample_name]) when is_binary(sample_name) do
    __bleep_ex_sample(lua, [sample_name, []])
  end

  def __bleep_ex_sample(lua, [sample_name, opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)
    tag = "*"

    broadcast({time_s, tag, {:sample, sample_name, output_id, opts}})
  end

  def __bleep_ex_play(lua, [note]) when is_integer(note) or is_float(note) do
    __bleep_ex_play(lua, [note, []])
  end

  def __bleep_ex_play(lua, [opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)
    synth = Bleep.VM.get_global(lua, "current_synth")
    tag = "*"

    broadcast({time_s, tag, {:synth, synth, output_id, opts}})
  end

  def __bleep_ex_play(lua, [note, opts_table]) when is_integer(note) or is_float(note) do
    __bleep_ex_play(lua, [[{"note", note} | opts_table]])
  end

  def __bleep_ex_control_fx(lua, [opts_table]) when is_list(opts_table) do
    __bleep_ex_control_fx(lua, [fetch_current_output_id(lua), opts_table])
  end

  def __bleep_ex_control_fx(lua, [uuid]) when is_binary(uuid) do
    __bleep_ex_control_fx(lua, [uuid, []])
  end

  def __bleep_ex_control_fx(lua, [uuid, opts_table]) when is_list(opts_table) do
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)
    tag = "*"

    broadcast({time_s, tag, {:core_control_fx, uuid, opts}})
  end

  def start_run(start_time_s, code, opts \\ %{}) do
    core_lua =
      if Mix.env() == :dev do
        File.read!(@core_lua_path)
      else
        @core_lua
      end

    bpm = opts[:bpm] || 60

    lua =
      Bleep.VM.make_vm(core_lua)
      ## Note that set_global prefixes with __bleep_core_ to avoid collisions
      |> Bleep.VM.set_global("bpm", bpm)
      |> Bleep.VM.set_global("start_time", start_time_s)
      |> Bleep.VM.set_global("global_time", 0)
      |> Bleep.VM.set_global("current_synth", "fmbell")
      |> Bleep.VM.set_global("current_fx_stack", ["default"])
      |> Bleep.VM.add_fn("__bleep_ex_play", &__bleep_ex_play/2)
      |> Bleep.VM.add_fn("__bleep_ex_sample", &__bleep_ex_sample/2)
      |> Bleep.VM.add_fn("__bleep_ex_control_fx", &__bleep_ex_control_fx/2)
      |> Bleep.VM.add_fn("__bleep_ex_start_fx", &__bleep_ex_start_fx/2)
      |> Bleep.VM.add_fn("__bleep_ex_stop_fx", &__bleep_ex_stop_fx/2)

    res_or_exception =
      try do
        Bleep.VM.eval(lua, code)
      rescue
        e ->
          {:exception, e, __STACKTRACE__}
      end

    res_or_exception
  end

  def fetch_current_output_id(lua_state) do
    Bleep.VM.get_global(lua_state, "current_fx_stack[#__bleep_core_current_fx_stack]")
  end

  def broadcast(msg) do
    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      msg
    )
  end
end