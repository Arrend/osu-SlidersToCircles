--Functions for finding the values and objects to do with time
local Utilities = require("Resources.Utilities")
local Timing = {
FindTimingPoints=(
function (lines)
  local startLine
  local timingPoints = {}
  local inheritedTimingPoints = {}
  for val=1, #lines do
    if lines[val] == "[TimingPoints]" then
      startLine = val+1
      break
    end
  end
  for val=startLine, #lines do
    local timingPointBlocks = Utilities.SeperateIntoBlocks(lines[val])
    if not timingPointBlocks[2] then break end    --After the last timing point it'll stop
    if tonumber(timingPointBlocks[2][1]) > 0 then
      --tblock[2] = time between beats at that bpm, pretty useful! Thanks Peppy
      table.insert(timingPoints, timingPointBlocks)
    else
      table.insert(inheritedTimingPoints, timingPointBlocks)
    end
  end
  return timingPoints, inheritedTimingPoints
end),

FindTimingPoint=(
function (timingPoints, time)
  local timingPoint
  for val=1, #timingPoints do
    if not timingPoint and tonumber(timingPoints[val][2][1]) > 0 then --Checks if it's the first non inherited timing point
      timingPoint = timingPoints[val]
    elseif math.floor(tonumber(timingPoints[val][1][1])) > time then
      break
    elseif not timingPoint then
      timingPoint = timingPoints[val]
    elseif tonumber(timingPoints[val][1][1]) <= time then
      timingPoint = timingPoints[val]
    end
  end
  return timingPoint
end),

FindTimingPointsBetween=(
function (timingPoints, tStart, tFinish)
  local applicableTimingPoints = {}
  for val=1, #timingPoints do
    if not applicableTimingPoints[1] then
      table.insert(applicableTimingPoints, timingPoints[val])
    elseif tonumber(timingPoints[val][1][1]) <= tStart then
      applicableTimingPoints[1] = timingPoints[val]
    elseif tonumber(timingPoints[val][1][1]) <= tFinish then
      table.insert(applicableTimingPoints, timingPoints[val])
    else
      --Since they're ordered by time, we can ignore every timing point after the slider ends
      break
    end
  end
  return applicableTimingPoints
end)
}

Timing["FindSliderTime"]=(
function (timingPoints, inheritedTimingPoints, sliderMultiplier, sliderLineBlocks)
  local timingPoint = Timing.FindTimingPoint(timingPoints, tonumber(sliderLineBlocks[3][1]))
  local inheritedTimingPoint = Timing.FindTimingPoint(inheritedTimingPoints, tonumber(sliderLineBlocks[3][1]))
  local pixelLength = sliderLineBlocks[8][1]
  local beatLength = timingPoint[2][1]
  if inheritedTimingPoint and tonumber(inheritedTimingPoint[1][1]) >= tonumber(timingPoint[1][1]) then
    sliderMultiplier = sliderMultiplier * math.abs(100/inheritedTimingPoint[2][1])
  end
  local sliderTime = (beatLength * pixelLength / sliderMultiplier) / 100
  return sliderTime
end)

return Timing
