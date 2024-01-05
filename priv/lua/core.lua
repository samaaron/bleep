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

local Ring = {}
Ring.__index = Ring

-- make a new ring from a lua array
-- array : the array to use as the initial contents
-- returns : a new Ring
function Ring.new(array)
    local self = setmetatable({}, Ring)
    self.array = array
    return self
end

-- make an empty ring of a given size containing zeros
-- size : the length of the ring
-- returns : a new Ring
function Ring.empty(size)
    local array = {}
    for i = 1, size do
        array[i] = 0
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
-- note that this uses 0 to n-1 indexing not lua indexing which is 1 to n
-- first : the first index
-- last : the last index
-- returns : a new Ring
function Ring:slice(first, last)
    first = math.max(1, first + 1)
    last = math.min(#self.array, last + 1)
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
        error("Parameter must be an instance of Ring", 2)
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
    return self:slice(0, #self.array - 2):concat(self:reverse())
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
    if index >= 0 then
        return (index % #self.array) + 1
    else
        return (#self.array + index) % #self.array + 1
    end
end

-- get a string representation of the ring
-- returns a comma-separated string of the values in the ring
function Ring.__tostring(self)
    return table.concat(self.array, ", ")
end

-- convenience function to make a ring
-- returns : a new Ring
function ring(array)
    return Ring.new(array)
end

--[[

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
    print("hello")
    if type(key) == "number" then
        local index = self.mapIndex(self, key)
        self.array[index] = value
    else
        rawset(self,key,value)
    end
end

]]

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
-- Pattern in x-xx or x-12 form
-- ===============================================================

-- make a Ring from a string pattern
-- seq : a string pattern containing "-" (rest), "x" hit or 1-9
-- "x" is mapped to 1 and "-" is mapped to 0
-- Elements in the range 1-9 are mapped into velocities in the range 0.1 to 0.9
function pattern(seq)
    local array = {}
    seq = seq:gsub("%s", "") -- remove any spaces
    for i = 1, #seq do
        local char = seq:sub(i, i)
        if (char == "x") then
            table.insert(array, 1)
        elseif char >= "1" and char <= "9" then
            table.insert(array, (string.byte(char)-string.byte("0"))/10)
        else
            table.insert(array, 0)
        end
    end
    return Ring.new(array)
end

-- helper functions

function hasBeat(pattern_name,index)
    return pattern_name:get(index)>0
end

-- ===============================================================
-- Euclidean rhythms
-- ===============================================================

-- hits - the number of steps that are drum hits
-- steps - the total number of steps in the sequence
-- phase (optional) - the phase offset (e.g. for phase=2 the pattern is right-shifted by two spaces)
-- returns a string of the form x--x-x- in which the hits are equally spaced in time
function euclideanPattern(hits, steps, phase)
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
function euclidean(hits,steps,phase)
    local seq = euclideanPattern(hits,steps,phase)
    return pattern(seq)
end

-- ===============================================================
-- play patterns 
-- ===============================================================

-- follows sonic pi approach for bad parameters
-- if the list of times is too short, repeat them from the start (a ring)
-- if the list of times is too long, ignore them
-- this works with a list of times or a single time
-- maybe we don't need play_pattern_timed?
-- gate is the gate duration (the proportion of the note duration that is actually played)
function play_pattern(notes,times,gate)
    if type(times) == "number" then
        times = {times}
    end
    if #times<1 then
        error("must have at least one time",2)
    end
    gate = gate or 1
    for i=1,#notes do
        local dur = times[ (i-1) % #times + 1]
        play(notes[i],{duration=dur*gate})
        sleep(dur)
    end
end

-- map operation on a table
function map(func,the_table)
    local new_table = {}
    for i,v in pairs(the_table) do
        new_table[i] = func(v)
    end
    return new_table
end

-- drum patterns

function drum_pattern(ptn, times, sample_name)
    if type(times) == "number" then
        times = { times }
    end
    if #times < 1 then
        error("must have at least one time", 2)
    end
    local p = pattern(ptn)
    for i = 0, p:length()-1 do
        local dur = times[(i - 1) % #times + 1]
        if (p:get(i)>0) then
            sample(sample_name)
        end
        sleep(dur)
    end
end
