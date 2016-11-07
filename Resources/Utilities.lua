--General Functions
local CreateVec2f = require("Resources.Vector")
local Utilities = {
SeperateIntoBlocks=(
function (line)
  local lineBlocks = {}
  local currentBlock = {}
  local previousComma = 0
  local points = 1
  for val=1, #line do
    local letter = string.sub(line, val, val)
    if letter == "," then
      table.insert(lineBlocks, currentBlock)
      currentBlock = {}
      points = 1
    elseif letter == "|" then
      points = points + 1
    else
      if currentBlock[points] == nil then
        currentBlock[points] = letter
      else
        currentBlock[points] = currentBlock[points] .. letter
      end
    end
  end
  table.insert(lineBlocks, currentBlock)
  return lineBlocks
end),

CreateNewLine=(
function (blocks, fileType)
  local newLine
  if fileType == 1 then
    if not blocks[9] then
      newLine = blocks[1][1] .. "," .. blocks[2][1] .. "," .. blocks[3][1] .. "," .. tonumber(blocks[4][1])-1 .. "," .. blocks[5][1] .. ",0:0:0:0:"
    else
      newLine = blocks[1][1] .. "," .. blocks[2][1] .. "," .. blocks[3][1] .. "," .. tonumber(blocks[4][1])-1 .. "," .. blocks[9][1] .. "," .. blocks[10][1]
    end
  elseif fileType == 2 then
    if not blocks[9] then
      newLine = blocks[1][1] .. "," .. blocks[2][1] .. "," .. blocks[3][1] .. "," .. tonumber(blocks[4][1])-1 .. "," .. blocks[5][1]
    else
      newLine = blocks[1][1] .. "," .. blocks[2][1] .. "," .. blocks[3][1] .. "," .. tonumber(blocks[4][1])-1 .. "," .. blocks[9][1]
    end
  end
  return newLine
end),

ReadResponse=(
function ()
  local response = io.read()
  if string.lower(response) == "exit" then
    os.exit()
  else
    return response
  end
end),

StringToVector=(
function (string)
  local markPoint
  for val=1, #string do
    if string.sub(string, val, val) == ":" then
      markPoint = val
      break
    end
  end
  local x, y = string.sub(string, 1, markPoint-1), string.sub(string, markPoint+1)
  return CreateVec2f():set(x, y)
end),

Lerp=(
function (a, b, t)
  return a * (1 - t) + b * t
end),

Round=(
function (x)
  return math.floor(x + 0.5)
end),

Intersect=(
function (a, ta, b, tb)
  local des = tb.x * ta.y - tb.y * ta.x
  if math.abs(des) < 0.00001 then
    print("Vectors are parallel")
    exit.os()
  end
  local u = ((b.y - a.y) * ta.x + (a.x - b.x) * ta.y) / des
  return b:cpy():add(tb.x * u, tb.y * u)
end),

isIn=(
function (a, b, c)    --Need to check this
  return ((b > a and b < c) or (b < a and b > c))
end),

CreateIterator=(
function (t)
  t["next"]=(
    function (self)
      if not self.i then
        self.n = 1
        self.i = 1
      else
        self.i = self.i + self.n
        if self.i > #self then
          self.i = 1
        end
      end
      return self[self.i]
    end)
  t["hasNext"]=(
    function (self)
      if not self.i or self[self.i+self.n] then
        return true
      end
    end)
  t["changDir"]=(
    function (self)
      self.n = - self.n
    end)
  return t
end)
}

Utilities["Copy"]=(
function (obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[Utilities.Copy(k, s)] = Utilities.Copy(v, s) end
  return res
end)

Utilities["CreateHitCircle"]=(
function (hitObject, instance, sliderTime, newComboOverride)
  if newComboOverride then hitObject[5] = 0 end
  if hitObject[1] == 1 then
    return (hitObject[2] .. "," .. hitObject[3] .. "," .. Utilities.Round(tonumber(hitObject[4]) + instance * sliderTime) .. "," .. (1+hitObject[5]) .. "," .. hitObject[6] .. ",0:0:0:0:")
  else
    return (hitObject[2] .. "," .. hitObject[3] .. "," .. Utilities.Round(tonumber(hitObject[4]) + instance * sliderTime) .. "," .. (1+hitObject[5]) .. "," .. hitObject[6])
  end
end)

return Utilities
