--Anything to do with reading the file is in here, no editing done
local Utilities = require("Resources.Utilities")
local FileHandling = {
GrabDiffName=(
function (mapName, extra)
  local one, two
  for val=1, #mapName do
    if string.sub(mapName, val, val) == "[" then
      one = val
    elseif string.sub(mapName, val, val) == "]" then
      two = val
      diffName = string.sub(mapName, one+1, two-1)
      newFileName = string.sub(mapName, 1, two-1) .. extra .. string.sub(mapName, two)
      return diffName, newFileName
    end
  end
end),

GrabTextFromFile=(
function (directory, newLines)
  local lines = {}
  local lineCount
  for line in io.lines(directory) do
    table.insert(lines, line)
    if not lineCount then
      table.insert(newLines, line)
    end
    if line == "[HitObjects]" then
      lineCount = #lines + 1
    end
  end
  return lines, lineCount
end),

GetOsuFileFormat=(
function (lines)
  local fileType
  local usingLine
  for val=1, #lines[1] do
    if string.sub(lines[1], val, val) == "o" then
      usingLine = string.sub(lines[1], val)
      break
    end
  end
  if not usingLine or string.sub(usingLine, 1, 17) ~= "osu file format v" then print("File is corrupt, or is not a osu! map file"); return end
  local excerpt = string.sub(usingLine, 18)
  if excerpt == "14" or excerpt == "13" or excerpt == "12" or excerpt == "10" then
    fileType = 1
  elseif excerpt == "9" or excerpt == "7" or excerpt == "6" then
    fileType = 2
  else
    print("This file type is not yet supported, or not yet checked to be supported.")
    return
  end
  return fileType
end),

GetSliderMultiplier=(
function (lines)
  local sliderMultiplier
  for val=1, #lines do
    if string.sub(lines[val], 1, 16) == "SliderMultiplier" then
      sliderMultiplier = tonumber(string.sub(lines[val], 18))
      break
    end
  end
  return sliderMultiplier
end)
}

return FileHandling
