defmodule Bleep.Content do
  def data_from_lua(path) do
    content_lua = File.read!(path)

    lua =
      Bleep.VM.make_vm("""

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

    content = Bleep.VM.lua_table_array_to_list(content)

    frags =
      Enum.map(content, fn frag_info ->
        frag_info = Bleep.VM.lua_table_to_map(frag_info)
        frag_info = Map.put(frag_info, :uuid, UUID.uuid4())
        frag_info
      end)

    %{frags: frags, init: init, author: author}
  end
end
