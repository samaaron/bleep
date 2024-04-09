defmodule Bleep.Content do
  def data_from_lua(path) do
    content_lua = File.read!(path)

    lua =
      Bleep.VM.make_vm("""

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
      """)

    {:ok, _result, lua_res} = Bleep.VM.eval(lua, content_lua)

    content = Bleep.VM.get_global(lua_res, "content") || []
    init = Bleep.VM.get_global(lua_res, "init") || ""
    author = Bleep.VM.get_global(lua_res, "author") || ""
    bpm = Bleep.VM.get_global(lua_res, "bpm")
    quantum = Bleep.VM.get_global(lua_res, "quantum")

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

    %{frags: frags, init: init, author: author, default_bpm: bpm, default_quantum: quantum}
  end
end
