local Resources = {
  FileHandling = require("Resources.FileHandling"),
  LinesGenerator = require("Resources.LinesGenerator"),
  Utilities = require("Resources.Utilities")
}
local Config = require("Config")
--local ExceptionHandling = require("ExceptionHandling")

local Main = {
ResponseHandling=(
function (self)
  local map
  while not map do
  --"C:\\Users\\Liam\\AppData\\Local\\osu!\\Songs\\125843 cosMo@BousouP featHatsune Miku - Hatsune Miku no Shoushitsu\\cosMo@BousouP feat.Hatsune Miku - Hatsune Miku no Shoushitsu (val0108) [Extra].osu"
  --Get file to change
  --[[
  io.write("Please enter the name of the folder the map is in\n")
  local folderName = readResponse()
  io.write("Please enter the name of the map\n")
  local mapName = readResponse()
  ]]
  io.write("Please drag the .osu file in\n")
  local directory = Resources.Utilities.ReadResponse()
  directory = directory:gsub("\\", "/")
  directory = directory:sub(2, -2)

  --Checks file is there
  --if string.lower(string.sub(mapName, -4)) ~= ".osu" then mapName = mapName .. ".osu" end
  --local directory = songFolderDirectory .. "\\" .. folderName .. "\\" .. mapName
  local map = io.open(directory, "r")
    if not map then
      print("Map not found: incorrect names given, or osu! song folder directory is not correct\n")
    else

      --Sets up information about file, also checks legitamacy of the file
      local diffName, newFileDirectory = Resources.FileHandling.GrabDiffName(directory, " No Circles")
      print(diffName .. "\n" .. newFileDirectory)
      if not diffName or not newFileDirectory then
        print("This file does not fit to osu! map name standards")
        map = nil
      else
        local newLines = {}
        local lines, lineCount = Resources.FileHandling.GrabTextFromFile(directory, newLines)
        if not lines or not lineCount then
          print("There are no lines in this file, or there is no subsection for hit objects")
          map = nil
        else
          local fileType = Resources.FileHandling.GetOsuFileFormat(lines)
          if not fileType then
            print("No applicable object format can be safely used")
            map = nil
          else
            local sliderMultiplier = Resources.FileHandling.GetSliderMultiplier(lines)
            --User chooses what to do with the file here
            io.write("Replace sliders with a circle, two circles, or a stream? Answer with 1, 2, or 3\n")
            local response = Resources.Utilities.ReadResponse()
            if response == "1" then
              local diffName, newFileDirectory = Resources.FileHandling.GrabDiffName(directory, " One Circle")
              --local newFileDirectory = songFolderDirectory .. "\\" .. folderName .. "\\" .. newFileName
              self:CreateFileSlidersToCircle(newFileDirectory, lines, lineCount, newLines, fileType)
              os.exit()
            elseif response == "2" then
              local diffName, newFileDirectory = Resources.FileHandling.GrabDiffName(directory, " Two Circles")
              --local newFileDirectory = songFolderDirectory .. "\\" .. folderName .. "\\" .. newFileName
              self:CreateFileSlidersToTwoCircles(newFileDirectory, lines, lineCount, newLines, fileType, sliderMultiplier)
              os.exit()
            elseif response == "3" then
              local diffName, newFileDirectory = Resources.FileHandling.GrabDiffName(directory, " Streams")
              self:CreateFileSlidersToStreams(newFileDirectory, lines, lineCount, newLines, fileType, sliderMultiplier)
              os.exit()
            else
              print("No usable answer given")
              map = nil
            end
          end
        end
      end
    end
  end
end),

CreateFileSlidersToCircle=(
function (self, newFileDirectory, lines, lineCount, newLines, fileType)
  local newFile = io.open(newFileDirectory, "w")
  newLines = Resources.LinesGenerator.ReconstructSliderAsCircle(lines, lineCount, newLines, fileType)
  for val=1, #newLines do
    if string.sub(newLines[val], 1, 7) == "Version" then
      newFile:write("Version:" .. diffName .. " One Circle\n")
    else
      newFile:write(newLines[val] .. "\n")
    end
  end
  newFile:close()
end),

CreateFileSlidersToTwoCircles=(
function (self, newFileDirectory, lines, lineCount, newLines, fileType, sliderMultiplier)
  local newFile = io.open(newFileDirectory, "w")
  newLines = Resources.LinesGenerator.ReconstructSliderAsTwoCircles(lines, lineCount, newLines, fileType, sliderMultiplier)
  for val=1, #newLines do
    if string.sub(newLines[val], 1, 7) == "Version" then
      newFile:write("Version:" .. diffName .. " Two Circles\n")
    else
      newFile:write(newLines[val] .. "\n")
    end
  end
  newFile:close()
end),

CreateFileSlidersToStreams=(
function (self, newFileDirectory, lines, lineCount, newLines, fileType, sliderMultiplier)
  local newFile = io.open(newFileDirectory, "w")
  newLines = Resources.LinesGenerator.ReconstructSliderAsStream(lines, lineCount, newLines, fileType, sliderMultiplier)
  for val=1, #newLines do
    if string.sub(newLines[val], 1, 7) == "Version" then
      newFile:write("Version:" .. diffName .. " Streams\n")
    else
      newFile:write(newLines[val] .. "\n")
    end
  end
  newFile:close()
end)
}

Main:ResponseHandling()
