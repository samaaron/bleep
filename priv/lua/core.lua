function uuid()
  __bleep_vm_uuid()
end

function run(label)
  if type(label) == "table" then
    for _, l in ipairs(label) do
      __bleep_ex_run_label(l)
    end
  else
    __bleep_ex_run_label(label)
  end
end

function play(note, opts_table)
  local opts_table = opts_table or {}
  if type(note) == "table" then
    for _, n in ipairs(note) do
      __bleep_ex_play(n, opts_table)
    end
  else
    __bleep_ex_play(note, opts_table)
  end
end

function sample(samp, opts_table)
  local opts_table = opts_table or {}
  __bleep_ex_sample(samp, opts_table)
end

function grains(samp, opts_table)
    local opts_table = opts_table or {}
    __bleep_ex_grains(samp, opts_table)
end

function sleep (t)
  __bleep_core_global_time = __bleep_core_global_time + t*60/__bleep_core_bpm
end

function push_fx(fx_id, opts_table)
  local opts_table = opts_table or {}
  local uuid = __bleep_vm_uuid()
  __bleep_ex_start_fx(uuid, fx_id, opts_table)
  table.insert(__bleep_core_current_fx_stack, uuid)
  return uuid
end

function pop_fx()
  if #__bleep_core_current_fx_stack == 1 then
    return
  end
  local uuid = table.remove(__bleep_core_current_fx_stack)
  __bleep_ex_stop_fx(uuid)
end

function pop_all_fx()
  for n = 2, #__bleep_core_current_fx_stack do
    pop_fx()
  end
end

function use_synth(s)
  __bleep_core_current_synth = s
end

function use_bpm(bpm)
  if type(bpm) ~= "number" then
    bpm = 60
  end

  if bpm < 1 then
    bpm = 1
  end

  if bpm > 999 then
    bpm = 999
  end

  __bleep_core_bpm = bpm
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

-- selects values from a ring given a list of indices
-- returns : a new Ring
function Ring:choose(list)
    local selected = {}
    for _,idx in ipairs(list) do
        table.insert(selected,self:get(idx))
    end
    return Ring.new(selected)
end

-- stretch the ring by duplicating each value
-- returns : a new Ring
function Ring:stretch(n)
    local stretched = {}
    for _, value in ipairs(self.array) do
        for k=1,n do
            table.insert(stretched, value)
        end
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

-- merge two rings by intercalating their values
function Ring:merge(another_ring)
    local fused = {}
    local n = math.max(self:length(),another_ring:length())
    for i=1,n do
        table.insert(fused, self[i])
        table.insert(fused, another_ring[i])
    end
    return Ring.new(fused)
end

-- find the maximum
function Ring:maximum()
    return maximum(self.array)
end

-- find the minimum
function Ring:minimum()
    return minimum(self.array)
end

-- invert
function Ring:invert()
    max_val = self:maximum()
    inverted = {}
    for i, val in ipairs(self.array) do
        inverted[i] = max_val-val
    end
    return Ring.new(inverted)
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

-- HELPER FUNCTIONS

-- helper function to make a ring
-- returns : a new Ring
function ring(array)
    return Ring.new(array)
end

function rand_ring(n,min,max)
    return Ring.random(n,min,max)
end

function const_ring(n,value)
    return Ring.constant(n,value)
end

function range_ring(n,min,max)
    return Ring.range(n,min,max)
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
function euclidean(hits, steps, phase)
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

-- ===============================================================
-- Scales
-- ===============================================================

scale_table = {}

-- modes

scale_table["aeolian"] = { 2, 1, 2, 2, 1, 2, 2 }
scale_table["dorian"] = { 2, 1, 2, 2, 2, 1, 2 }
scale_table["ionian"] = { 2, 2, 1, 2, 2, 2, 1 }
scale_table["locrian"] = { 1, 2, 2, 1, 2, 2, 2 }
scale_table["lydian"] = { 2, 2, 2, 1, 2, 2, 1 }
scale_table["mixolydian"] = { 2, 2, 1, 2, 2, 1, 2 }
scale_table["phrygian"] = { 1, 2, 2, 2, 1, 2, 2 }

-- common scales

scale_table["ascending_melodic_minor"] = { 2, 1, 2, 2, 2, 2, 1 }
scale_table["blues"] = { 3, 2, 1, 1, 3, 2 }
scale_table["harmonic_minor"] = { 2, 1, 2, 2, 1, 3, 1 }
scale_table["major"] = scale_table["ionian"]
scale_table["major_pentatonic"] = { 2, 2, 3, 2, 3 }
scale_table["minor_pentatonic"] = { 3, 2, 2, 3, 2 }
scale_table["natural_minor"] = scale_table["aeolian"]
scale_table["whole_tone"] = { 2, 2, 2, 2, 2, 2 }

-- altered scales

scale_table["altered"] = { 1, 2, 1, 2, 2, 2, 2 }
scale_table["bebop_dominant"] = { 2, 2, 1, 2, 2, 1, 1, 1 }
scale_table["freygish"] = scale_table["phrygian_dominant"]
scale_table["half_whole_diminished"] = { 1, 2, 1, 2, 1, 2, 1, 2 }
scale_table["lydian_augmented"] = { 2, 2, 2, 2, 1, 2, 1 }
scale_table["lydian_dominant"] = { 2, 2, 2, 1, 2, 1, 2 }
scale_table["phrygian_dominant"] = { 1, 3, 1, 2, 1, 2, 2 }
scale_table["whole_half_diminished"] = { 2, 1, 2, 1, 2, 1, 2, 1 }

-- Indian scales

scale_table["raga_bhairav"] = { 1, 3, 1, 2, 1, 3, 1 }
scale_table["raga_bhairavi"] = { 1, 2, 2, 2, 1, 2, 2 }
scale_table["raga_pahadi"] = { 2, 2, 3, 2, 3 }
scale_table["raga_pilu"] = { 2, 1, 1, 1, 2, 1, 1, 1, 1, 1 }
scale_table["raga_marwa"] = { 1, 3, 2, 3, 2, 1 }
scale_table["raga_yaman"] = { 2, 2, 2, 1, 2, 2, 1 }

-- Middle Eastern

scale_table["byzantine"] = scale_table["raga_bhairav"]
scale_table["double_harmonic"] = scale_table["raga_bhairav"]
scale_table["maqam_hijaz"] = scale_table["phrygian_dominant"]

-- Other world and exotic scales

scale_table["enigmatic"] = { 1, 3, 2, 2, 2, 1, 1 }
scale_table["hirajoshi"] = { 2, 1, 4, 1, 4 }
scale_table["hungarian_major"] = { 3, 1, 2, 1, 2, 1, 2 }
scale_table["hungarian_minor"] = { 2, 1, 3, 1, 1, 3, 1 }
scale_table["neapolitan_major"] = { 1, 2, 2, 2, 2, 2, 1 }
scale_table["neapolitan_minor"] = { 1, 2, 2, 2, 1, 3, 1 }
scale_table["prometheus"] = { 2, 2, 2, 3, 1, 2 }

-- Gamelan scales
-- https://www.youtube.com/watch?v=_7ltggbNGZ8
-- https://www.youtube.com/watch?v=-44PKBHPQG4
-- divide cents by 100 and then subtract sucessive values to get MIDI note intervals

scale_table["pelog_begbeg"] = { 1.2, 1.14, 4.32, 0.81, 4.53 }
scale_table["pelog_sedeng"] = { 1.36, 1.55, 3.79, 1.34, 3.96 }
scale_table["pelog_tirus"] = { 1.97, 1.8, 3.47, 1.04, 3.72 }

scale_table["slendro_manisrenga"] = { 2.195, 2.665, 2.27, 2.335, 2.585 }
scale_table["slendro_rarasrum"] = { 2.295, 2.275, 2.53, 2.32, 2.615 }
scale_table["slendro_surak"] = { 2.06, 2.315, 2.385, 2.65, 2.645 }

-- Make a scale, which is returned as a Ring as in Sonic Pi
-- intervals : table of intervals, passed directly or one of the defined scales
-- root : the root note (MIDI number, note name or even a float, it doesn't matter)
-- octaves : the number of octaves (optional, defaults to 1)
function scale(name, root, octaves)
    local intervals = scale_table[name] or major
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

-- =============================================================================
-- Swing patterns
-- =============================================================================

function swing_8ths(amount,dur)
    local delta = dur*amount/200
    return Ring.new({dur, dur+delta,dur-delta,dur})
end

function swing_16ths(amount,dur)
    local delta = dur*amount/200
    return Ring.new({dur+delta,dur-delta})
end

-- =============================================================================
-- Play patterns
-- =============================================================================

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
        -- updated 25/1/24 to allow rests (zero note values) in the patterns
        if (note>0) then
            play(note,note_params)
        end
        sleep(dur)
    end
end

-- =============================================================================
-- Drum patterns
-- =============================================================================

function drum_pattern(pattern, params)
    -- remove spaces
    pattern = pattern:gsub("%s", "")
    -- parameter map
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
        if type(value) == "number" then
            -- if the value is a number turn it into a ring
            param_map[key] = Ring.new({ value })
        elseif type(value) == "string" then
                -- if the value is a string add it directly
                param_map[key] = value
            elseif isRing(value) then
            -- a ring already so just set it
            param_map[key] = value
        elseif type(value) == "table" then
            -- a table is fine as it is (could be a table of numbers)
            param_map[key] = Ring.new(value)
        else
            -- we got something else, an error
            error("parameters must be single numbers or lists", 2)
        end
    end
    -- main loop
    local sleep_duration = 0
    for i = 1,#pattern do
        local this_char = pattern:sub(i,i)
        local beat_params = {}
        local dur = param_map.duration and param_map.duration[i] or 1
        for key, param_ring in pairs(param_map) do
            -- only add params to the sample function if they are not single characters
            -- and not a duration, other stuff gets passed on
            if key ~= "duration" and #key>1 then
                beat_params[key] = param_ring[i]
            end
        end
        if this_char ~= "-" then
            local samp = param_map[this_char] or "elec_blip"
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

-- =============================================================================
-- Compressor presets, borrowed from Ableton
-- =============================================================================

COMPRESS_GENERIC = {attack=10/1000,release=100/1000,ratio=2,threshold=-21.5,knee=0.7}
COMPRESS_PEAKS = {attack=2/1000,release=50/1000,ratio=2,threshold=0,knee=6}
COMPRESS_KICKS = {attack=30/1000,release=120/1000,ratio=4,threshold=-14.9,knee=0.4}
COMPRESS_CLASSIC = {attack=0.22/1000,release=100/1000,ratio=1.15,threshold=-9.7,knee=6}
COMPRESS_SNARE = {attack=3/1000,release=150/1000,ratio=4.74,threshold=-19.2,knee=0}
COMPRESS_MEDIUM = {attack=25.9/1000,release=100/1000,ratio=4,threshold=-22.8,knee=4}
COMPRESS_BRUTE = {attack=0.01/1000,release=10.2/1000,ratio=12.6,threshold=-31.9,knee=0}
COMPRESS_WALL = {attack=0.02/1000,release=100/1000,ratio=20,threshold=-9.7,knee=1}
COMPRESS_GENTLE = {attack=1/1000,release=100/1000,ratio=1.5,threshold=-21.5,knee=12}
COMPRESS_GLUE = {attack=12.5/1000,release=1,ratio=1.2,threshold=-22.1,knee=12}
COMPRESS_ACOUSTIC = {attack=17.9/1000,release=222/1000,ratio=2.25,threshold=-17.5,knee=7.7}
COMPRESS_PRECISE = {attack=0.88/1000,release=100/1000,ratio=1.54,threshold=-28.7,knee=6}

-- =============================================================================
-- Random functions
-- =============================================================================

function randi(min, max)
    return math.random(min, max)
end

function randf(min, max)
    return min + math.random() * (max - min)
end

function dice(n)
    if (n < 1) then
        error("dice: argument must be greater than 0")
    end
    return math.random(1, n)
end

function set_seed(seed)
    if seed then
        math.randomseed(seed)
    else
        math.randomseed(os.time())
    end
end

