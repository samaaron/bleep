defmodule Bleep.Lang do
  @core_lua_path Path.join([:code.priv_dir(:bleep), "lua", "core.lua"])
  @core_lua File.read!(@core_lua_path)

  require Logger

  @moduledoc """
  This module is responsible for evaluating Lua code and sending the results

  """

  def lua_time(lua) do
    global_time_s = Bleep.VM.get_global(lua, "__bleep_core_global_time")
    start_time_s = Bleep.VM.get_global(lua, "__bleep_core_start_time")
    global_time_s + start_time_s + 1.5
  end

  def __bleep_ex_start_fx(user_id, editor_id, run_id, lua, [uuid, fx_id]) do
    __bleep_ex_start_fx(user_id, editor_id, run_id, lua, [uuid, fx_id, []])
  end

  def __bleep_ex_start_fx(user_id, editor_id, run_id, lua, [uuid, fx_id, opts_table]) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)

    msg = %{
      user_id: user_id,
      editor_id: editor_id,
      run_id: run_id,
      time_s: time_s,
      cmd: "triggerFX",
      fx_id: fx_id,
      uuid: uuid,
      output_id: output_id,
      opts: opts
    }

    bleep_broadcast(user_id, "sched-bleep-audio", msg)
  end

  def __bleep_ex_stop_fx(user_id, editor_id, run_id, lua, [fx_id]) do
    time_s = lua_time(lua)

    msg = %{
      user_id: user_id,
      editor_id: editor_id,
      run_id: run_id,
      fx_id: fx_id,
      time_s: time_s,
      cmd: "releaseFX"
    }

    bleep_broadcast(user_id, "sched-bleep-audio", msg)
  end

  def __bleep_ex_sample(user_id, editor_id, run_id, lua, [sample_name])
      when is_binary(sample_name) do
    __bleep_ex_sample(user_id, editor_id, run_id, lua, [sample_name, []])
  end

  def __bleep_ex_sample(user_id, editor_id, run_id, lua, [sample_name, opts_table])
      when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)

    msg = %{
      user_id: user_id,
      editor_id: editor_id,
      run_id: run_id,
      time_s: time_s,
      cmd: "triggerSample",
      sample_name: sample_name,
      output_id: output_id,
      opts: opts
    }

    bleep_broadcast(user_id, "sched-bleep-audio", msg)
  end

  def __bleep_ex_play(user_id, editor_id, run_id, lua, [note])
      when is_integer(note) or is_float(note) do
    __bleep_ex_play(user_id, editor_id, run_id, lua, [note, []])
  end

  def __bleep_ex_play(user_id, editor_id, run_id, lua, [opts_table]) when is_list(opts_table) do
    output_id = fetch_current_output_id(lua)
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)
    synth = Bleep.VM.get_global(lua, "__bleep_core_current_synth")

    msg = %{
      user_id: user_id,
      editor_id: editor_id,
      run_id: run_id,
      time_s: time_s,
      cmd: "triggerOneShotSynth",
      synthdef_id: synth,
      output_id: output_id,
      opts: opts
    }

    bleep_broadcast(user_id, "sched-bleep-audio", msg)
  end

  def __bleep_ex_play(user_id, editor_id, run_id, lua, [note, opts_table])
      when is_integer(note) or is_float(note) do
    __bleep_ex_play(user_id, editor_id, run_id, lua, [[{"note", note} | opts_table]])
  end

  def __bleep_ex_control_fx(user_id, editor_id, run_id, lua, [opts_table])
      when is_list(opts_table) do
    __bleep_ex_control_fx(user_id, editor_id, run_id, lua, [
      fetch_current_output_id(lua),
      opts_table
    ])
  end

  def __bleep_ex_control_fx(user_id, editor_id, run_id, lua, [uuid]) when is_binary(uuid) do
    __bleep_ex_control_fx(user_id, editor_id, run_id, lua, [uuid, []])
  end

  def __bleep_ex_control_fx(user_id, editor_id, run_id, lua, [fx_id, opts_table])
      when is_list(opts_table) do
    time_s = lua_time(lua)
    opts = Bleep.VM.lua_table_to_map(opts_table)

    msg = %{
      user_id: user_id,
      editor_id: editor_id,
      run_id: run_id,
      fx_id: fx_id,
      time_s: time_s,
      cmd: "controlFX",
      opts: opts
    }

    bleep_broadcast(user_id, "sched-bleep-audio", msg)
  end

  def stop_editor_runs(user_id, editor_id) do
    bleep_broadcast(user_id, "stop-editor-runs", %{editor_id: editor_id})
  end

  def start_run(user_id, editor_id, start_time_s, code, init_code, opts \\ %{}) do
    core_lua =
      if Application.get_env(:bleep, :reload_lua) do
        # for dev environments reload the lua file on each run
        File.read!(@core_lua_path)
      else
        @core_lua
      end

    bpm = opts[:bpm] || 60
    run_id = UUID.uuid4()

    lua =
      Bleep.VM.make_vm(core_lua)
      ## Note that set_global prefixes with __bleep_core_ to avoid collisions
      |> Bleep.VM.set_global("__bleep_core_user_id", user_id)
      |> Bleep.VM.set_global("__bleep_core_editor_id", editor_id)
      |> Bleep.VM.set_global("__bleep_core_run_id", run_id)
      |> Bleep.VM.set_global("__bleep_core_bpm", bpm)
      |> Bleep.VM.set_global("__bleep_core_start_time", start_time_s)
      |> Bleep.VM.set_global("__bleep_core_global_time", 0)
      |> Bleep.VM.set_global("__bleep_core_current_synth", "fmbell")
      |> Bleep.VM.set_global("__bleep_core_current_fx_stack", ["default"])
      |> Bleep.VM.add_fn(
        "__bleep_ex_play",
        &__bleep_ex_play(user_id, editor_id, run_id, &1, &2)
      )
      |> Bleep.VM.add_fn(
        "__bleep_ex_sample",
        &__bleep_ex_sample(user_id, editor_id, run_id, &1, &2)
      )
      |> Bleep.VM.add_fn(
        "__bleep_ex_control_fx",
        &__bleep_ex_control_fx(user_id, editor_id, run_id, &1, &2)
      )
      |> Bleep.VM.add_fn(
        "__bleep_ex_start_fx",
        &__bleep_ex_start_fx(user_id, editor_id, run_id, &1, &2)
      )
      |> Bleep.VM.add_fn(
        "__bleep_ex_stop_fx",
        &__bleep_ex_stop_fx(user_id, editor_id, run_id, &1, &2)
      )

    res_or_exception =
      try do
        {:ok, _res, lua} = Bleep.VM.eval(lua, init_code)
        Bleep.VM.eval(lua, code)
      rescue
        e ->
          {:exception, e, __STACKTRACE__}
      end

    res_or_exception
  end

  def fetch_current_output_id(lua_state) do
    Bleep.VM.get_global(
      lua_state,
      "__bleep_core_current_fx_stack[#__bleep_core_current_fx_stack]"
    )
  end

  def bleep_broadcast(user_id, event, msg) do
    topic = "bleep-audio:" <> user_id

    BleepWeb.Endpoint.broadcast(
      topic,
      event,
      msg
    )
  end
end
