defmodule Bleep.Content do
  def data_from_lua(path) do
    content_lua = File.read!(path)

    lua =
      Bleep.VM.make_vm("""
      function markdown(s)
        return {
          kind = "markdown",
          content = s,
          uuid = __bleep_vm_uuid()
        }
      end

      function editor(s)
        return {
          kind = "editor",
          content = s,
          lang = "lua",
          uuid = __bleep_vm_uuid()
        }
      end
      """)

    {:ok, [result | _rest], _lua} = Bleep.VM.eval(lua, content_lua)
    result = Bleep.VM.lua_table_array_to_list(result)

    Enum.map(result, fn frag_info ->
      frag_info = Bleep.VM.lua_table_to_map(frag_info)
      frag_info = Map.put(frag_info, :uuid, UUID.uuid4())
      frag_info
    end)
  end
end
