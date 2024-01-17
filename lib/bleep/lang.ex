defmodule Bleep.Lang do
  @core_lua_path Path.join([:code.priv_dir(:bleep), "lua", "core.lua"])
  @core_lua File.read!(@core_lua_path)

  require Logger

  @moduledoc """
  This module is responsible for evaluating Lua code and sending the results

  """

  def lua_time(lua) do
    {[global_time_s | _rest], lua} = :luerl.do(<<"return bleep_global_time">>, lua)
    {[start_time_s | _rest], _lua} = :luerl.do(<<"return bleep_start_time">>, lua)
    global_time_s + start_time_s
  end

  def bleep_core_start_fx(lua, [uuid, fx_id]) do
    bleep_core_start_fx(lua, [uuid, fx_id, []])
  end

  def bleep_core_start_fx(lua, [uuid, fx_id, opts_table]) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)

    tag = "*"

    broadcast({time_s, tag, {:core_start_fx, uuid, fx_id, output_id, opts}})
  end

  def bleep_core_stop_fx(lua, [uuid]) do
    time_s = lua_time(lua)
    opts = %{}
    tag = "*"

    broadcast({time_s, tag, {:core_stop_fx, uuid, opts}})
  end

  def sample(lua, [sample_name]) when is_binary(sample_name) do
    sample(lua, [sample_name, []])
  end

  def sample(lua, [sample_name, opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)
    tag = "*"

    broadcast({time_s, tag, {:sample, sample_name, output_id, opts}})
  end

  def play(lua, [note]) when is_integer(note) or is_float(note) do
    play(lua, [note, []])
  end

  def play(lua, [opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)
    {[synth | _rest], _lua} = :luerl.do(<<"return bleep_current_synth">>, lua)
    tag = "*"

    broadcast({time_s, tag, {:synth, synth, output_id, opts}})
  end

  def play(lua, [note, opts_table]) when is_integer(note) or is_float(note) do
    play(lua, [[{"note", note} | opts_table]])
  end

  def control_fx(lua, [opts_table]) when is_list(opts_table) do
    control_fx(lua, [fetch_current_output_id(lua), opts_table])
  end

  def control_fx(lua, [uuid]) when is_binary(uuid) do
    control_fx(lua, [uuid, []])
  end

  def control_fx(lua, [uuid, opts_table]) when is_list(opts_table) do
    time_s = lua_time(lua)
    opts = lua_table_to_map(opts_table)
    tag = "*"

    broadcast({time_s, tag, {:core_control_fx, uuid, opts}})
  end

  def start_run(start_time_s, code) do
    core_lua =
      if Mix.env() == :dev do
        File.read!(@core_lua_path)
      else
        @core_lua
      end

    lua = Bleep.VM.make_vm(core_lua)

    global_state_init = """
    bleep_start_time = #{start_time_s}
    bleep_global_time = 0
    bleep_current_synth = "fmbell"
    bleep_current_fx_stack = { "default" }
    """

    {:ok, _res, lua} = Bleep.VM.eval(global_state_init, lua)

    lua = Bleep.VM.add_fn("play", &play/2, lua)
    lua = Bleep.VM.add_fn("sample", &sample/2, lua)
    lua = Bleep.VM.add_fn("control_fx", &control_fx/2, lua)
    lua = Bleep.VM.add_fn("bleep_core_start_fx", &bleep_core_start_fx/2, lua)
    lua = Bleep.VM.add_fn("bleep_core_stop_fx", &bleep_core_stop_fx/2, lua)

    res_or_exception =
      try do
        Bleep.VM.eval(code, lua)
      rescue
        e ->
          {:exception, e, __STACKTRACE__}
      end

    res_or_exception
  end

  def lua_table_to_map(table) do
    Enum.reduce(table, %{}, fn
      {k, v}, acc when is_binary(k) ->
        Map.put(acc, String.to_atom(k), v)

      {k, v}, acc ->
        Map.put(acc, k, v)
    end)
  end

  def fetch_current_output_id(lua_state) do
    {[fx_id | _rest], _lua} =
      :luerl.do(<<"return bleep_current_fx_stack[#bleep_current_fx_stack]">>, lua_state)

    fx_id
  end

  def lua_table_array_to_list(table) do
    map = lua_table_to_map(table)
    array_map_to_list(map)
  end

  def array_map_to_list(map, index \\ 1) do
    case Map.has_key?(map, index) do
      true ->
        [Map.get(map, index) | array_map_to_list(map, index + 1)]

      false ->
        []
    end
  end

  def broadcast(msg) do
    BleepWeb.Endpoint.broadcast(
      "room:bleep-audio",
      "msg",
      msg
    )
  end
end
