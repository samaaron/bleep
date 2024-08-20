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


      function editor(...)
        local args = {...}  -- Capture all arguments in a table
        local frag_id = __bleep_vm_uuid()
        local name
        local content

        if #args == 1 then
          -- If only one argument, assume it's just markdown
          name = nil
          content = args[1]
        elseif #args == 2 then
          name = args[1]
          content = args[2]
        else
          error("Invalid number of arguments. Expected 1 or 2 arguments, got " .. #args)
        end

        return {
          kind = "editor",
          lang = "lua",
          content = content,
          frag_id = frag_id,
          editor_name = name
        }
      end

      function markdown(s)
        return {
          kind = "markdown",
          content = s,
          frag_id = __bleep_vm_uuid()
        }
      end

      function video(s)
        return {
          kind = "video",
          src = s,
          frag_id = __bleep_vm_uuid()
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

    {frags, _editor_count} =
      Enum.map_reduce(content_list, 1, fn frag_info, editor_count ->
        frag_info_map = Bleep.VM.lua_table_to_map(frag_info)

        case Map.get(frag_info_map, :kind) do
          "editor" ->
            updated_map =
              Map.put(
                frag_info_map,
                :editor_name,
                Map.get(frag_info_map, :editor_name) || Integer.to_string(editor_count) <> "."
              )

            {updated_map, editor_count + 1}

          _ ->
            {frag_info_map, editor_count}
        end
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
