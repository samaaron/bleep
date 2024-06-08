defmodule Bleep.Content do
  def data_from_lua_file(path) do
    content_lua = File.read!(path)
    data_from_lua(content_lua)
  end

  def data_from_lua(content_lua) do
    lua =
      Bleep.VM.make_vm("""
      title = ""
      description = ""
      init = ""
      author = ""
      bpm = 60
      quantum = 4
      content = {}

      function markdown(s)
        return {
          kind = "markdown",
          content = s,
        }
      end

      function editor(s)
        return {
          kind = "editor",
          content = s,
          lang = "lua",
        }
      end

      function video(s)
        return {
          kind = "video",
          src = s,
        }
      end
      """)

    {:ok, _result, lua_res} = Bleep.VM.eval(lua, content_lua)

    content = Bleep.VM.get_global(lua_res, "content") || []
    init = Bleep.VM.get_global(lua_res, "init") || ""
    author = Bleep.VM.get_global(lua_res, "author") || ""
    bpm = Bleep.VM.get_global(lua_res, "bpm")
    quantum = Bleep.VM.get_global(lua_res, "quantum")
    title = Bleep.VM.get_global(lua_res, "title")
    description = Bleep.VM.get_global(lua_res, "description") || ""

    bpm =
      cond do
        is_integer(bpm) -> bpm
        is_float(bpm) -> bpm
        is_binary(bpm) -> String.to_integer(bpm)
        true -> 60
      end

    content_list = Bleep.VM.lua_table_array_to_list(content)

    frags =
      Enum.map(content_list, fn frag_info ->
        frag_info = Bleep.VM.lua_table_to_map(frag_info)

        frag_info
        |> Map.put(:frag_id, UUID.uuid4())
      end)

    %{
      source: content_lua,
      frags: frags,
      init: init,
      author: author,
      default_bpm: bpm,
      default_quantum: quantum,
      title: title,
      description: description
    }
  end
end
