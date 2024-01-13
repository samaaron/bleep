function sleep (t)
  bleep_global_time = bleep_global_time + t
end

function push_fx(fx_id, opts_table)
  local opts_table = opts_table or {}
  local uuid = uuid()
  bleep_core_start_fx(uuid, fx_id, opts_table)
  table.insert(bleep_current_fx_stack, uuid)
  return uuid
end

function pop_fx()
  if #bleep_current_fx_stack == 1 then
    return
  end
  local uuid = table.remove(bleep_current_fx_stack)
  bleep_core_stop_fx(uuid)
end

function use_synth(s)
  bleep_current_synth = s
end

function shuffle(x)
  local shuffled = {}
  for i, v in ipairs(x) do
	  local pos = math.random(1, #shuffled+1)
	  table.insert(shuffled, pos, v)
  end
  return shuffled
end

function pick(x)
  return shuffle(x)[1]
end

-- =============================================================================
-- Utility functions
-- =============================================================================

function tableToString(tbl)
    local str = "{"
    for key, value in pairs(tbl) do
        str = str .. key .. "=" .. tostring(value) .. ", "
    end
    -- Remove the last comma and space if the table is not empty
    if str ~= "{" then
        str = str:sub(1, -3)
    end
    str = str .. "}"
    return str
end

function isListOfNumbers(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    local count = 0
    for key, value in pairs(tbl) do
        -- Check if the key is a consecutive integer
        if type(key) ~= "number" or key ~= count + 1 then
            return false
        end
        -- Check if the value is a number
        if type(value) ~= "number" then
            return false
        end
        count = count + 1
    end
    return true
end

-- =============================================================================
-- Make a global variable for each MIDI note name
-- =============================================================================

function make_note_names()
  local note_names = { "C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B" }
  local note_ptr = 10
  local octave = 0
  for n = 21, 127 do
      note_id = note_names[note_ptr] .. octave
      _G[note_id] = n -- _G is the table of globals
      note_ptr = note_ptr + 1
      if (note_ptr > 12) then
          note_ptr = 1
          octave = octave + 1
      end
  end
end

make_note_names()

-- ===============================================================
-- Ring abstraction strongly based on Sonic Pi
-- ===============================================================

Ring = {}
Ring.__index = Ring

-- define table indexing operator for reading from a ring 
function Ring:__index(key)
    if type(key) == "number" then
        local index = self.mapIndex(self, key)
        return self.array[index]
    else
        return Ring[key]
    end
end

-- define table indexing operator for writing to a ring 
function Ring:__newindex(key, value)
    if type(key) == "number" then
        local index = self.mapIndex(self, key)
        self.array[index] = value
    else
        rawset(self,key,value)
    end
end

-- make a new ring from a lua array
-- array : the array to use as the initial contents
-- returns : a new Ring
function Ring.new(array)
    local self = setmetatable({}, Ring)
    self.array = array
    self._type = "TYPE_RING"
    return self
end

-- make an ring of a given size containing a constant value
-- size : the length of the ring
-- returns : a new Ring
function Ring.constant(size,value)
    local array = {}
    for i = 1, size do
        array[i] = value
    end
    return Ring.new(array)
end

-- make an ring of a given size containing random values in a range
-- size : the length of the ring
-- returns : a new Ring
function Ring.random(size,min,max)
    min = min or 0
    max = max or 1
    local array = {}
    for i = 1, size do
        array[i] = min+(max-min)*math.random()
    end
    return Ring.new(array)
end

-- make a range of values of a given size 
-- size : the length of the ring
-- returns : a new Ring
function Ring.range(size,min,max)
    local array = {}
    local step = (max-min)/(size-1)
    for i = 1, size do
        array[i] = min+step*(i-1)
    end
    return Ring.new(array)
end

-- set a value of the ring
-- value : the value to set
-- index : the index to set 
function Ring:set(value, index)
    local i = self.mapIndex(self, index)
    self.array[i] = value
end

-- get a value of the ring
-- index : the index to get
-- returns : the value at the given index
function Ring:get(index)
    local i = self.mapIndex(self, index)
    return self.array[i]
end

-- pick random values from the ring
-- n : the number of random values to pick
-- returns : a new Ring
function Ring:pick(n)
    n = math.max(1, n)
    local picked = {}
    for i = 1, n do
        picked[i] = self.array[math.random(1, #self.array)]
    end
    return Ring.new(picked)
end

-- quantize values in the ring to a specific grid size
-- this will fail if grid_size is zero 
-- grid_size : the size of the grid
-- returns : a new Ring
function Ring:quantize(grid_size)
    if grid_size==0 then
        error("grid size cannot be zero",2)
    end
    local quantized = {}
    for i = 1, #self.array do
        quantized[i] = math.floor(self.array[i]/grid_size+0.5)*grid_size
    end
    return Ring.new(quantized)
end

-- make a new ring containing multiple copies of the current ring
-- n : the number of copies
-- returns : a new Ring
function Ring:clone(n)
    n = math.max(1, n)
    local result = {}
    for i = 1, n do
        for _, value in ipairs(self.array) do
            table.insert(result, value)
        end
    end
    return Ring.new(result)
end

-- shuffle the values in the ring
-- returns : a new Ring
function Ring:shuffle()
    local array_copy = self.arrayCopy(self)
    for i = #self.array, 2, -1 do
        local j = math.random(i)
        array_copy[i], array_copy[j] = array_copy[j], array_copy[i]
    end
    return Ring.new(array_copy)
end

-- reverse the values in the ring
-- returns : a new Ring
function Ring:reverse()
    local array_copy = self.arrayCopy(self)
    local i, j = 1, #array_copy
    while i < j do
        array_copy[i], array_copy[j] = array_copy[j], array_copy[i]
        i = i + 1
        j = j - 1
    end
    return Ring.new(array_copy)
end

-- stretch the ring by duplicating each value
-- returns : a new Ring
function Ring:stretch()
    local stretched = {}
    for _, value in ipairs(self.array) do
        table.insert(stretched, value)
        table.insert(stretched, value)
    end
    return Ring.new(stretched)
end

-- creating alternating intervals by duplicating each value and adding a constant
-- returns : a new Ring
function Ring:alternate(n)
    local alternating = {}
    for _, value in ipairs(self.array) do
        table.insert(alternating, value)
        table.insert(alternating, value+n)
    end
    return Ring.new(alternating)
end

-- get the length of the ring
-- returns : the number of elements in the ring
function Ring:length()
    return #self.array
end

-- get the first n elements from the ring
-- n : the number of elements
-- returns : a new Ring
function Ring:head(n)
    if (n < 1) then
        error("Parameter must be at least 1", 2)
    end
    return self:slice(0, n - 1)
end

-- get the last n elements from the ring
-- n : the number of elements
-- returns : a new Ring
function Ring:tail(n)
    if (n < 1) then
        error("Parameter must be at least 1", 2)
    end
    return self:slice(#self.array - n, #self.array - 1)
end

-- get a slice from the ring
-- note that this uses lua indexing from 1 to n (not from zero)
-- first : the first index
-- last : the last index
-- returns : a new Ring
function Ring:slice(first, last)
    first = math.max(1, first)
    last = math.min(#self.array, last)
    local sliced = {}
    for i = first, last do
        sliced[i - first + 1] = self.array[i]
    end
    return Ring.new(sliced)
end

-- concatenate one ring with another ring
-- another_ring : the ring to concatenate with this one
-- returns : a new Ring
function Ring:concat(another_ring)
    if getmetatable(another_ring) ~= Ring then
        error("Parameter must be an instance of Ring or an array", 2)
    end
    local array_copy = self.arrayCopy(self)
    for _, value in ipairs(another_ring.array) do
        table.insert(array_copy, value)
    end
    return Ring.new(array_copy)
end

-- multiply all of the elements in the ring by a scalar value
-- s : the scalar value
-- returns : a new Ring
function Ring:multiply(s)
    local array_copy = self.arrayCopy(self)
    for i = 1, #array_copy do
        array_copy[i] = array_copy[i] * s
    end
    return Ring.new(array_copy)
end

-- add a scalar value to all elements of the ring
-- s : the scalar value
-- returns : a new Ring
function Ring:add(s)
    local array_copy = self.arrayCopy(self)
    for i = 1, #array_copy do
        array_copy[i] = array_copy[i] + s
    end
    return Ring.new(array_copy)
end

-- mirror the ring, the middle value is repeated 
-- returns : a new Ring
function Ring:mirror()
    return self:concat(self:reverse())
end

-- mirror the ring, the middle value is not repeated
-- returns : a new Ring
function Ring:reflect()
    return self:slice(1, #self.array - 1):concat(self:reverse())
end

-- sort the ring in ascending order
-- returns : a new Ring
function Ring:sort()
    local array_copy = self.arrayCopy(self)
    table.sort(array_copy)
    return Ring.new(array_copy)
end

-- copy the array for this ring
-- used internally
-- returns : an array
function Ring:arrayCopy()
    local array_copy = {}
    for _, value in ipairs(self.array) do
        table.insert(array_copy, value)
    end
    return array_copy
end

-- map an index to the ring, wrapping positive and negative values
-- index : the index to wrap 
-- returns : the integer index
function Ring:mapIndex(index)
    return (index-1) % #self.array + 1
end

-- map function, returns a new ring in which func has been applied
-- to every element 
-- func : the funtion to apply
-- returns : a new Ring
function Ring:map(func)
    local new_table = {}
    for i,v in ipairs(self.array) do
        new_table[i] = func(v)
    end
    return Ring.new(new_table)
end

-- intercalate two rings
function Ring:intercalate(another_ring)
    local fused = {}
    local n = math.max(self:length(),another_ring:length())
    for i=1,n do
        table.insert(fused, self[i])
        table.insert(fused, another_ring[i])
    end
    return Ring.new(fused)
end

-- get a string representation of the ring
-- returns a comma-separated string of the values in the ring
function Ring.__tostring(self)
    local elements = {}
    for i, val in ipairs(self.array) do
        if type(val) == "boolean" then
            elements[i] = val and "true" or "false"
        else
            elements[i] = tostring(val)  -- Convert non-boolean values to string
        end
    end
    return table.concat(elements, ", ")
end

-- convenience function to make a ring
-- returns : a new Ring
function ring(array)
    return Ring.new(array)
end

-- I think this could be a bit nasty but it works
-- Lua does not allow user-defined types
function isRing(obj)
    return type(obj)=="table" and obj._type=="TYPE_RING"
end


-- ===============================================================
-- Euclidean rhythms 
-- ===============================================================

-- hits - the number of steps that are drum hits
-- steps - the total number of steps in the sequence 
-- phase (optional) - the phase offset (e.g. for phase=2 the pattern is right-shifted by two spaces)
-- returns a string of the form x--x-x- in which the hits are equally spaced in time
function euclidean_pattern(hits, steps, phase)
    phase = phase or 0
    local pattern = {}
    local slope = hits / steps
    local previous = -1
    for i = 0, steps - 1 do
        local current = math.floor(i * slope)
        pattern[1 + (i + phase) % steps] = current ~= previous and "x" or "-"
        previous = current
    end
    -- concatenate the table into a string
    return table.concat(pattern)
end

-- make a Euclidean rhythm 
-- returns a Ring containing the pattern, with ones for hits and zeros for rests
function euclidean_ring(hits,steps,phase)
    local seq = euclidean_pattern(hits,steps,phase)
    return pattern(seq)
end

-- ===============================================================
-- Scales
-- ===============================================================

-- modes

aeolian = { 2, 1, 2, 2, 1, 2, 2 }
dorian = { 2, 1, 2, 2, 2, 1, 2 }
ionian = { 2, 2, 1, 2, 2, 2, 1 }
locrian = { 1, 2, 2, 1, 2, 2, 2 }
lydian = { 2, 2, 2, 1, 2, 2, 1 }
mixolydian = { 2, 2, 1, 2, 2, 1, 2 }
phrygian = { 1, 2, 2, 2, 1, 2, 2 }

-- common scales

ascending_melodic_minor = { 2, 1, 2, 2, 2, 2, 1 }
blues = { 3, 2, 1, 1, 3, 2 }
harmonic_minor = { 2, 1, 2, 2, 1, 3, 1 }
major = ionian
major_pentatonic = { 2, 2, 3, 2, 3 }
minor_pentatonic = { 3, 2, 2, 3, 2 }
natural_minor = aeolian
whole_tone = { 2, 2, 2, 2, 2, 2 }

-- altered scales

altered = { 1, 2, 1, 2, 2, 2, 2 }
bebop_dominant = { 2, 2, 1, 2, 2, 1, 1, 1 }
freygish = phrygian_dominant
half_whole_diminished = { 1, 2, 1, 2, 1, 2, 1, 2 }
lydian_augmented = { 2, 2, 2, 2, 1, 2, 1 }
lydian_dominant = { 2, 2, 2, 1, 2, 1, 2 }
phrygian_dominant = { 1, 3, 1, 2, 1, 2, 2 }
whole_half_diminished = { 2, 1, 2, 1, 2, 1, 2, 1 }

-- Indian scales

raga_bhairav = { 1, 3, 1, 2, 1, 3, 1 }
raga_bhairavi = half_whole_diminished
raga_hamsadhwani = lydian
raga_malkauns = minor_pentatonic
raga_marwa = { 3, 1, 2, 2, 1, 3, 1 }
raga_yaman = ionian

-- Middle Eastern

byzantine = raga_bhairav
double_harmonic = raga_bhairav
maqam_hijaz = phrygian_dominant

-- Other world and exotic scales

enigmatic = { 1, 3, 2, 2, 2, 1, 1 }
hirajoshi = { 2, 1, 4, 1, 4 }
hungarian_major_scale = { 3, 1, 2, 1, 2, 1, 2 }
hungarian_minor = { 2, 1, 3, 1, 1, 3, 1 }
neapolitan_major = { 1, 2, 2, 2, 2, 2, 1 }
neapolitan_minor = { 1, 2, 2, 2, 1, 3, 1 }
prometheus = { 2, 2, 2, 3, 1, 2 }

-- Gamelan scales
-- https://www.youtube.com/watch?v=_7ltggbNGZ8
-- https://www.youtube.com/watch?v=-44PKBHPQG4
-- divide cents by 100 and then subtract sucessive values to get MIDI note intervals

pelog_begbeg = { 1.2, 1.14, 4.32, 0.81, 4.53 }
pelog_sedeng = { 1.36, 1.55, 3.79, 1.34, 3.96 }
pelog_tirus = { 1.97, 1.8, 3.47, 1.04, 3.72 }

slendro_manisrenga = { 2.195, 2.665, 2.27, 2.335, 2.585 }
slendro_rarasrum = { 2.295, 2.275, 2.53, 2.32, 2.615 }
slendro_surak = { 2.06, 2.315, 2.385, 2.65, 2.645 }

-- Make a scale, which is returned as a Ring as in Sonic Pi
-- intervals : table of intervals, passed directly or one of the defined scales
-- root : the root note (MIDI number, note name or even a float, it doesn't matter)
-- octaves : the number of octaves (optional, defaults to 1)
function scale(intervals, root, octaves)
    local num_octaves = octaves or 1
    local n = 1 + num_octaves * #intervals
    local array = {}
    local note = root
    for i = 1, n do
        table.insert(array, note)
        local k = (i - 1) % #intervals + 1
        note = note + intervals[k]
    end
    return Ring.new(array)
end

-- ===============================================================
-- Playing patterns
-- ===============================================================

function play_pattern(notes, params)
    local param_map = {}
    -- this error checking could be more precise
    if type(notes)~="table" then
        error("expected a list or ring of notes", 2)
    end
    if params == nil then
        params = {}
    end
    if type(params) ~= "table" then
        error("expected a list of parameters", 2)
    end
    -- get the list of key,value parameter pairs
    for key, value in pairs(params) do
        -- if the key is a number then we didnt get a key value pair, just a single value
        if type(key) == "number" then
            error("parameter list must contain key value pairs", 2)
        end
        -- we have a valid key, so check the value
        if type(value) == "number" or type(value)=="boolean" then
            -- if the value is a number turn it into a ring 
            param_map[key] = Ring.new({ value })
        elseif isRing(value) then
            -- a ring already so just set it
            param_map[key] = value
        elseif type(value)=="table" then
            -- a table is fine, turn it into a ring 
            param_map[key] = Ring.new(value)
        else
            -- we got something else, an error
            error("parameters must be single numbers or lists of numbers", 2)
        end
    end
    -- if notes is a ring we just want its array
    -- to be on the safe side we take a deep copy of this to avoid any inadvertent change to the ring 
    if isRing(notes) then
        notes = notes:arrayCopy()
    end
    -- main loop to make the parameters for each note
    for i, note in ipairs(notes) do
        local note_params = {}
        local gate = param_map.gate and param_map.gate[i] or 1
        local dur = param_map.duration and param_map.duration[i] or 1
        note_params["duration"] = dur * gate
        for key, param_ring in pairs(param_map) do
            if key ~= "duration" and key ~= "gate" then
                note_params[key] = param_ring[i]
            end
        end
        play(note,note_params)
        sleep(dur)
    end
end

-- ===============================================================
-- Drum patterns
-- ===============================================================

-- make a Ring from a string pattern
-- "x" is mapped to 1 and "-" is mapped to 0
function patternToTable(seq)
    local array = {}
    seq = seq:gsub("%s", "") -- remove any spaces
    for i = 1, #seq do
        local char = seq:sub(i, i)
        if (char == "x") then
            table.insert(array, 1)
        else
            table.insert(array, 0)
        end
    end
    return array
end

function drum_pattern(pattern, params)
    local beats = patternToTable(pattern)
    local param_map = {}
    if params == nil then
        params = {}
    end
    if type(params) ~= "table" then
        error("expected a list of parameters", 2)
    end
    -- get the list of key,value parameter pairs
    for key, value in pairs(params) do
        -- if the key is a number then we didnt get a key value pair, just a single value
        if type(key) == "number" then
            error("parameter list must contain key value pairs", 2)
        end
        -- we have a valid key, so check the value
        if type(value) == "number" or type(value) == "string" then
            -- if the value is a number or string turn it into a ring
            param_map[key] = Ring.new({ value })
        elseif isRing(value) then
            -- a ring already so just set it
            param_map[key] = value
        elseif type(value) == "table" then
            -- a table is fine as it is (could be numbers or strings)
            param_map[key] = Ring.new(value)
        else
            -- we got something else, an error
            error("parameters must be single numbers or lists", 2)
        end
    end
    -- main loop
    local sleep_duration = 0
    for i, beat in ipairs(beats) do
        local beat_params = {}
        local dur = param_map.duration and param_map.duration[i] or 1
        local samp = param_map.sample and param_map.sample[i] or "elec_blip"
        for key, param_ring in pairs(param_map) do
            if key ~= "sample" and key ~= "duration" then
                beat_params[key] = param_ring[i]
            end
        end
        if beat == 1 then
            if sleep_duration > 0 then
                sleep(sleep_duration)
                sleep_duration = 0
            end
            sample(samp, beat_params)
            sleep_duration = sleep_duration + dur
        else
            sleep_duration = sleep_duration + dur
        end
    end
    if sleep_duration > 0 then
        sleep(sleep_duration)
    end
end

-- ===============================================================
-- Grooves
-- ===============================================================

function swing_8ths(amount,dur)
    local delta = dur*amount/200
    return Ring.new({dur, dur+delta,dur-delta,dur})
end

function swing_16ths(amount,dur)
    local delta = dur*amount/200
    return Ring.new({dur+delta,dur-delta})
end
