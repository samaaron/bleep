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
