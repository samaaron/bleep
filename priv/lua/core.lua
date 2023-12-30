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

-- =============================================================================
-- Pattern - represents a x-xx-xx- style pattern
-- =============================================================================

local Pattern = {}
Pattern.__index = Pattern

-- constructor
-- seq - string of the form x-xx-x
function Pattern.new(seq)
    local self = setmetatable({}, Pattern)
    self.seq = seq:gsub("%s","") -- remove any spaces
    self.ptr = 1
    return self
end

-- return true if the next element of the pattern is a hit ("x")
function Pattern:next()
    local b = self.seq:sub(self.ptr, self.ptr) == "x"
    self.ptr = self.ptr + 1
    if (self.ptr > #self.seq) then
        self.ptr = 1
    end
    return b
end

-- go back to the start of the pattern
function Pattern:reset()
    self.ptr = 1
end

-- get the string repesentation of this pattern
function Pattern.__tostring(self)
    return self.seq
end

-- convenience function to make a pattern
function pattern(seq)
    return Pattern.new(seq)
end

-- =============================================================================
-- Euclidean patterns
-- =============================================================================

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

-- convenience function to make a euclidean pattern
function euclidean(hits, steps, phase)
    local seq = euclideanPattern(hits, steps, phase)
    return Pattern.new(seq)
end

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
