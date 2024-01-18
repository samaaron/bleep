return {

    markdown [[
    ### Lua redux - Map function for rings and array indexing
    * Map function added as Sam suggested.
    * Indexing has been changed so that Rings start at 1, consistent with Lua tables (otherwise moving between
    rings and Lua tables will get very confusing I think).
    * Array indexes can now be used to set and get values in a Ring.
    ]],
    
    editor [[
    use_synth("sawlead")
    push_fx("reverb", {wetLevel=0.2})
    
    -- set up some notes
    
    the_notes = ring({C3,D3,E3,F3,G3})
    
    -- map function suggested by Sam
    
    the_notes:map(function (n)
        play(n, {duration=0.12})
        sleep(0.125)
    end)

}