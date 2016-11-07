--Functions that create the lines in the new .osu file
local Utilities = require("Resources.Utilities")
local Timing = require("Resources.Timing")
local SliderGenerator = require("Resources.SliderGenerator")
local Config = require("Config")
local LinesGenerator = {
ReconstructSliderAsCircle=(
function (lines, lineCount, newLines, fileType)
  for val=lineCount, #lines do
    local newLineBlocks = Utilities.SeperateIntoBlocks(lines[val])
    local newLine = lines[val]
    newLineBlocks[4][1] = tonumber(newLineBlocks[4][1])
    if (newLineBlocks[4][1] - math.floor(newLineBlocks[4][1]/2)*2 == 0) and (newLineBlocks[4][1] ~= 12) then
      newLine = Utilities.CreateNewLine(newLineBlocks, fileType)
    end
    table.insert(newLines, newLine)
  end
  return newLines
end),

ReconstructSliderAsTwoCircles=(
function (lines, lineCount, newLines, fileType, sliderMultiplier)
  local timingPoints, inheritedTimingPoints = Timing.FindTimingPoints(lines)
  --local sliderMultiplier = GetSliderMultiplier(lines)
  for val=lineCount, #lines do
    local newLineBlocks = Utilities.SeperateIntoBlocks(lines[val])
    local newLine = lines[val]
    newLineBlocks[4][1] = tonumber(newLineBlocks[4][1])
    if (newLineBlocks[4][1] - math.floor(newLineBlocks[4][1]/2)*2 == 0) and (newLineBlocks[4][1] ~= 12) then
      local startTime, sliderTime = tonumber(newLineBlocks[3][1]), Timing.FindSliderTime(timingPoints, inheritedTimingPoints, sliderMultiplier, newLineBlocks)
      local sliderType = newLineBlocks[6][1]
      local slider = {Utilities.StringToVector(newLineBlocks[1][1]..":"..newLineBlocks[2][1])}
      for val=2, #newLineBlocks[6] do
        table.insert(slider, Utilities.StringToVector(newLineBlocks[6][val]))
      end
      local sliderCurve = SliderGenerator.GetSliderCurve(newLineBlocks, false, slider)
      if sliderCurve then
        if Config.Minlen[1] and Config.Minlen[2] < sliderTime then
          newLine = {}
          local sliderStartCircle
          local sliderEndCircle
          --fileType, time, hitX, hitY, newCombo, hitsound, extra1, extra2
          if newLineBlocks[10] then
            sliderStartCircle = {fileType, newLineBlocks[1][1], newLineBlocks[2][1], startTime, (tonumber(newLineBlocks[4][1])-2), newLineBlocks[9][1], newLineBlocks[10][1], newLineBlocks[11][1]}
            sliderEndCircle = {fileType, Utilities.Round(sliderCurve:pointAt(1).x), Utilities.Round(sliderCurve:pointAt(1).y), startTime, (0), newLineBlocks[9][2], newLineBlocks[10][2], newLineBlocks[11][1]}
          else
            sliderStartCircle = {fileType, newLineBlocks[1][1], newLineBlocks[2][1], startTime, (tonumber(newLineBlocks[4][1])-2), newLineBlocks[5][1], "0:0:", "0:0:"}
            sliderEndCircle = {fileType, Utilities.Round(sliderCurve:pointAt(1).x), Utilities.Round(sliderCurve:pointAt(1).y), startTime, (0), newLineBlocks[5][1], "0:0:", "0:0:"}
          end
          local iter = Utilities.CreateIterator({sliderStartCircle, sliderEndCircle})
          local hitObject = iter:next()
          table.insert(newLine, Utilities.CreateHitCircle(hitObject, 0, sliderTime))
          for val=1, tonumber(newLineBlocks[7][1]) do
            hitObject = iter:next()
            table.insert(newLine, Utilities.CreateHitCircle(hitObject, val, sliderTime, 1))
          end
        end
      end
    end
    if type(newLine) == "table" then
      for i=1, #newLine do
        table.insert(newLines, newLine[i])
      end
    else
      table.insert(newLines, newLine)
    end
  end
  return newLines
end),

ReconstructSliderAsStream=(
function (lines, lineCount, newLines, fileType, sliderMultiplier)
  local timingPoints, inheritedTimingPoints = Timing.FindTimingPoints(lines)
  for val=lineCount, #lines do
    local newLineBlocks = Utilities.SeperateIntoBlocks(lines[val])
    local newLine = lines[val]
    newLineBlocks[4][1] = tonumber(newLineBlocks[4][1])
    if (newLineBlocks[4][1] - math.floor(newLineBlocks[4][1]/2)*2 == 0) and (newLineBlocks[4][1] ~= 12) then
      local startTime, sliderTime = tonumber(newLineBlocks[3][1]), Timing.FindSliderTime(timingPoints, inheritedTimingPoints, sliderMultiplier, newLineBlocks)
      local sliderType = newLineBlocks[6][1]
      local slider = {Utilities.StringToVector(newLineBlocks[1][1]..":"..newLineBlocks[2][1])}
      for val=2, #newLineBlocks[6] do
        table.insert(slider, Utilities.StringToVector(newLineBlocks[6][val]))
      end
      local sliderCurve = SliderGenerator.GetSliderCurve(newLineBlocks, false, slider)
      if sliderCurve and (tonumber(newLineBlocks[8][1]) >= 5) then
        if not Config.Minlen[1] or Config.Minlen[2] < sliderTime then
          newLine = {}
          local timingPoint = Timing.FindTimingPoint(timingPoints, startTime)
          local streamTime
          local o1o16time = tonumber(timingPoint[2][1])/16
          local divisorsf = sliderTime / o1o16time
          local divisors = Utilities.Round(divisorsf)
          if math.abs(divisors - divisorsf) <= 0.15 then  --Determines that it is not a 1/3 rhythm, has a preference for 1/4 over 1/3
            streamTime = tonumber(timingPoint[2][1])/4    --The default is 1/4 streams
          else
            streamTime = tonumber(timingPoint[2][1])/3  --The default is 1/3 streams
            print(startTime)
            print("And the divisors " .. divisorsf .. " " .. divisors)
          end
          while streamTime > sliderTime * 1.2 do  --If it should be 1/8 instead of 1/4    Done before Config setup kicks in
            streamTime = streamTime / 2
          end
          if Config.Minms[1] then
            if streamTime < Config.Minms[2] then
              repeat
                streamTime = streamTime * 2
              until streamTime >= Config.Minms[2]
            end
          end
          --Swapping these around would mean being below the lower limit bpm is more important than being above the upper limit bpm
          if Config.Maxms[1] then
            if streamTime > Config.Maxms[2] then
              repeat
                streamTime = streamTime / 2
              until streamTime <= Config.Maxms[2]
            end
          end
          --If the slider is 1/8 and we're trying to make a 1/4 stream, this needs to change !!!
          local numCircles = Utilities.Round(sliderTime / streamTime)  --Number of extra circles after the first initial circle. Also the extra circles per repeat
          local circPositions = {{newLineBlocks[1][1], newLineBlocks[2][1]}}
          for val=1, numCircles do
            table.insert(circPositions, {Utilities.Round(sliderCurve:pointAt(val/numCircles).x), Utilities.Round(sliderCurve:pointAt(val/numCircles).y)})
          end
          local hitObjects = {}
          local sliderStartCircle
          local sliderEndCircle
          if newLineBlocks[10] then
            sliderStartCircle = {fileType, circPositions[1][1], circPositions[1][2], startTime, (tonumber(newLineBlocks[4][1])-2), newLineBlocks[9][1], newLineBlocks[10][1], newLineBlocks[11][1]}
            sliderEndCircle = {fileType, circPositions[#circPositions][1], circPositions[#circPositions][2], startTime, (0), newLineBlocks[9][2], newLineBlocks[10][2], newLineBlocks[11][1]}
          else
            sliderStartCircle = {fileType, circPositions[1][1], circPositions[1][2], startTime, (tonumber(newLineBlocks[4][1])-2), newLineBlocks[5][1], "0:0:", "0:0:"}
            sliderEndCircle = {fileType, circPositions[#circPositions][1], circPositions[#circPositions][2], startTime, (0), newLineBlocks[5][1], "0:0:", "0:0:"}
          end
          table.insert(hitObjects, sliderStartCircle)
          --Need here to grab the slider hitsound and add in config for stream hitsounding
          for val=2, numCircles do
            table.insert(hitObjects, {fileType, circPositions[val][1], circPositions[val][2], startTime, (0), (0), "0:0:", "0:0:"})
          end
          table.insert(hitObjects, sliderEndCircle)
          local iter = Utilities.CreateIterator(hitObjects)
          local hitObject = iter:next()
          table.insert(newLine, Utilities.CreateHitCircle(hitObject, 0, sliderTime))
          for val=1, (numCircles * tonumber(newLineBlocks[7][1])) do
            hitObject = iter:next()
            table.insert(newLine, Utilities.CreateHitCircle(hitObject, val, streamTime, 1))
            if not iter:hasNext() then
              iter:changDir()
            end
          end
        end
      end
    end
    if type(newLine) == "table" then
      for i=1, #newLine do
        table.insert(newLines, newLine[i])
      end
    else
      table.insert(newLines, newLine)
    end
  end
  return newLines
end)
}

return LinesGenerator
