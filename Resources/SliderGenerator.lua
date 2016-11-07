--Taken from Opsu
--Functions used to create an instance of a slider to obtain circle positions
local CreateVec2f = require("Resources.Vector")
local Utilities = require("Resources.Utilities")
local SliderGenerator = {
EqualDistanceMultiCurve={__index = function (table, key)
  return EqualDistanceMultiCurveFunctions[key]
end},

CurveType={__index = function (table, key)
  return CurveTypeFunctions[key]
end}
}

EqualDistanceMultiCurveFunctions = {
  init=(
    function (self)
      self.ncurve = (self.size / 5) + 2 --Enter in global (curve point seperation)
      self.curve = {}
      local distanceAt = 0
      local iter = Utilities.CreateIterator(self.curves)
      local curPoint = 1
      local curCurve = iter:next()
      local lastCurve = curCurve:getCurvePoint()[1]
      local lastDistanceAt = 0

      for val=1, self.ncurve do
        local prefDistance = (val-1) * self.size / self.ncurve
        while (distanceAt < prefDistance) do
          lastDistanceAt = distanceAt
          lastCurve = curCurve:getCurvePoint()[curPoint]
          curPoint = curPoint + 1

          if curPoint >= curCurve:getCurvesCount() then
            if iter:hasNext() then
              curCurve = iter:next()
              curPoint = 1
            else
              curPoint = curCurve:getCurvesCount() - 1
              if lastDistanceAt == distanceAt then
                --Out of points even though the preferred distance hasn't been reached
                break
              end
            end
          end
          distanceAt = distanceAt + curCurve:getCurveDistances()[curPoint]
        end
        local thisCurve = curCurve:getCurvePoint()[curPoint]

        if distanceAt - lastDistanceAt > 1 then
          local t = (prefDistance - lastDistanceAt) / (distanceAt - lastDistanceAt)
          self.curve[val] = CreateVec2f():set(Utilities.Lerp(lastCurve.x, thisCurve.x, t), Utilities.Lerp(lastCurve.y, thisCurve.y, t))
        else
          self.curve[val] = thisCurve
        end
      end
    end),

    pointAt=(
      function (self, t)
        local indexF = (t * (#self.curve-1))+1
        local index = math.floor(indexF)  --Will check this later if it is accurate (it's not truncating like in java)
        if index >= #self.curve then
          return self.curve[#self.curve]:cpy()
        else
          local poi = self.curve[index]
          local poi2 = self.curve[index+1]
          local t2 = indexF - index
          return CreateVec2f():set(Utilities.Lerp(poi.x, poi2.x, t2), Utilities.Lerp(poi.y, poi2.y, t2))
        end
      end)
}

CurveTypeFunctions = {
  init=(
    function (self, bezierPoints)
      self.ncurve = (self.approxLength / 4) + 2
      self.curve = {}
      for val=1, self.ncurve do
        self.curve[val] = self:pointAt(val/(self.ncurve-1))
      end

      self.curveDis = {}
      self.totalDistance = 0
      for val=1, self.ncurve do
        self.curveDis[val] = (val == 1) and 0 or self.curve[val]:cpy():subV(self.curve[val-1]):len()
        self.totalDistance = self.totalDistance + self.curveDis[val]
      end
    end),

    getCurvePoint=(
      function (self)
        return self.curve
      end),

    getCurvesCount=(
      function (self)
        return self.ncurve
      end),

    getCurveDistances=(
      function (self)
        return self.curveDis
      end)
}

local LinearBezierFunctions = {
  create=(
    function (self, sliderPoints, line, scaled, size)
      self.size = size
      self.beziers = {}
      local bezierPoints = {}
      local lastPoi
      for val=1, #sliderPoints do
        local tpoi = sliderPoints[val]
        if line then
          if lastPoi then
            table.insert(bezierPoints, tpoi)
            --Create Bezier
            table.insert(self.beziers, SliderGenerator.CreateBezier(bezierPoints))
            bezierPoints = {}
          end
        elseif lastPoi and tpoi:equals(lastPoi) then
          if #bezierPoints >= 2 then
            --Create Bezier
            table.insert(self.beziers, SliderGenerator.CreateBezier(bezierPoints))
          end
          bezierPoints = {}
        end
        table.insert(bezierPoints, tpoi)
        lastPoi = tpoi
      end
      if line or #bezierPoints < 2 then
      else
        --Create Bezier
        table.insert(self.beziers, SliderGenerator.CreateBezier(bezierPoints))
        bezierPoints = {}
      end
      self.curves = self.beziers
      self:init()
    end)
}

local BezierFunctions = {
  create=(
    function (self, bezierPoints)
      self.points = bezierPoints
      self.approxLength = 0
      for val=1, #self.points-1 do
        self.approxLength = self.approxLength + self.points[val]:cpy():subV(self.points[val+1]):len()
      end
      self:init()
    end),

  pointAt=(
    function (self, t)
      local c = CreateVec2f():set(0, 0)
      local n = #self.points-1
      for i=0, n do
        b = self:bernstein(i, n, t)
        c.x = c.x + self.points[i+1].x * b
        c.y = c.y + self.points[i+1].y * b
      end
      return c
    end),

  binomialCoefficient=(
    function (self, n, k)
      if k < 0 or k > n then
        return 0
      elseif k == 0 or k == n then
        return 1
      else
        k = math.min(k, n - k)
        c = 1
        for i=0, k-1 do
          c = c * (n - i) / (i + 1)
        end
        return c
      end
    end),

  bernstein=(
    function (self, i, n, t)
      return self:binomialCoefficient(n, i) * math.pow(t, i) * math.pow(1 - t, n - i)
    end)
}

local CatmullFunctions = {
  create=(
    function (self, sliderPoints, scaled, size)
      self.size = size
      self.catmulls = {}
      local points = {}
      self.ncontrolPoints = #sliderPoints+1
      if sliderPoints[1].x ~= sliderPoints[2].x and sliderPoints[1].y ~= sliderPoints[2].y then
        table.insert(points, sliderPoints[1]:cpy())
      end
      for val=1, self.ncontrolPoints-1 do
        table.insert(points, sliderPoints[val]:cpy())
        if #points >= 4 then
          table.insert(self.catmulls, SliderGenerator.CreateCentripetalCatmullRom(points))
          table.remove(points, 1)
        end
      end
      if sliderPoints[#sliderPoints].x ~= sliderPoints[#sliderPoints-1].x and sliderPoints[#sliderPoints].y ~= sliderPoints[#sliderPoints-1].y then
        table.insert(points, sliderPoints[#sliderPoints]:cpy())
      end
      if #points >= 4 then
        table.insert(self.catmulls, SliderGenerator.CreateCentripetalCatmullRom(points))
      end
      self.curves = self.catmulls
      self:init()
    end)
}

local CentripetalCatmullRomFunctions = {
  create=(
    function (self, catmullPoints)
      if #catmullPoints ~= 4 then
        print("Incorrect amount of points entered for a Catmull Curve")
        os.exit()
      end
      self.points = catmullPoints
      self.time = {}
      self.approxLength = 0
      for val=1, 4 do
        local len = 0
        if val > 1 then
          len = self.points[val]:cpy():subV(self.points[val-1]):len()
        end
        if len <= 0 then
          len = len + 0.0001
        end
        self.approxLength = self.approxLength + len
        self.time[val] = val
      end
      self:init(self.approxLength/2)
  end),

  pointAt=(
    function (self, t)
      t = t * (self.time[3] - self.time[2]) + self.time[2]
      local points, time = self.points, self.time

      local A1 = points[1]:cpy():scale((time[2] - t) / (time[2] - time[1])):addV(points[2]:cpy():scale((t - time[1]) / (time[2] - time[1])));
		  local A2 = points[2]:cpy():scale((time[3] - t) / (time[3] - time[2])):addV(points[3]:cpy():scale((t - time[2]) / (time[3] - time[2])));
		  local A3 = points[3]:cpy():scale((time[4] - t) / (time[4] - time[3])):addV(points[4]:cpy():scale((t - time[3]) / (time[4] - time[3])));

		  local B1 = A1:cpy():scale((time[3] - t) / (time[3] - time[1])):addV(A2:cpy():scale((t - time[1]) / (time[3] - time[1])));
		  local B2 = A2:cpy():scale((time[4] - t) / (time[4] - time[2])):addV(A3:cpy():scale((t - time[2]) / (time[4] - time[2])));

		  local C = B1:cpy():scale((time[3] - t) / (time[3] - time[2])):addV(B2:cpy():scale((t - time[2]) / (time[3] - time[2])));

		  return C
    end)
}

local CircumscribedCircleFunctions = {
  create=(
    function (self, sliderPoints, scaled, size)
      local TWO_PI = 2 * math.pi
      local HALF_PI = 0.5 * math.pi

      self.start = sliderPoints[1]:cpy()
      self.mid = sliderPoints[2]:cpy()
      self.finish = sliderPoints[3]:cpy()

      local mida = self.start:midPoint(self.mid)
      local midb = self.finish:midPoint(self.mid)
      local nora = self.mid:cpy():subV(self.start):nor()
      local norb = self.mid:cpy():subV(self.finish):nor()

      self.circleCentre = Utilities.Intersect(mida, nora, midb, norb)

      local startAngPoint = self.start:cpy():subV(self.circleCentre)
      local midAngPoint = self.mid:cpy():subV(self.circleCentre)
      local finishAngPoint = self.finish:cpy():subV(self.circleCentre)

      self.startAng = math.atan2(startAngPoint.y, startAngPoint.x)
      self.midAng = math.atan2(midAngPoint.y, midAngPoint.x)
      self.finishAng = math.atan2(finishAngPoint.y, finishAngPoint.x)

      if not Utilities.isIn(self.startAng, self.midAng, self.finishAng) then
        if (math.abs(self.startAng + TWO_PI - self.finishAng) < TWO_PI and Utilities.isIn(self.startAng + (TWO_PI), self.midAng, self.finishAng)) then
				  self.startAng = self.startAng + TWO_PI
			  elseif (math.abs(self.startAng - (self.finishAng + TWO_PI)) < TWO_PI and Utilities.isIn(self.startAng, self.midAng, self.finishAng + (TWO_PI))) then
          self.finishAng = self.finishAng + TWO_PI
			  elseif (math.abs(self.startAng - TWO_PI - self.finishAng) < TWO_PI and Utilities.isIn(self.startAng - (TWO_PI), self.midAng, self.finishAng)) then
				  self.startAng = self.startAng - TWO_PI
			  elseif (math.abs(self.startAng - (self.finishAng - TWO_PI)) < TWO_PI and Utilities.isIn(self.startAng, self.midAng, self.finishAng - (TWO_PI))) then
          self.finishAng = self.finishAng - TWO_PI
			  else
          print("Cannot find angles between midAng " .. self.startAng .. " " .. self.midAng .. " " .. self.finishAng)
        end
      end

      self.radius = startAngPoint:len()
      self.size = size
      local arcAng = self.size / self.radius

      self.finishAng = (self.finishAng > self.startAng) and (self.startAng + arcAng) or (self.startAng - arcAng)

      self.drawEndAngle = ((self.finishAng + (self.startAng > self.finishAng and HALF_PI or - HALF_PI)) * 180 / math.pi)
      self.drawStartAngle = ((self.startAng + (self.startAng > self.finishAng and - HALF_PI or HALF_PI)) * 180 / math.pi)

      local step = self.size / 5
      self.curve = {}
      for val=0, step do
        self.curve[val+1] = self:pointAt(val/step)
      end
    end),

  pointAt=(
    function (self, t)
      local ang = Utilities.Lerp(self.startAng, self.finishAng, t)
      return CreateVec2f():set((math.cos(ang) * self.radius + self.circleCentre.x), (math.sin(ang) * self.radius + self.circleCentre.y))
    end)
}

SliderGenerator["CreateLinearBezier"]=(
function (sliderPoints, line, scaled, size)
  local LinearBezier = Utilities.Copy(LinearBezierFunctions)
  setmetatable(LinearBezier, SliderGenerator.EqualDistanceMultiCurve)

  LinearBezier:create(sliderPoints, line, scaled, size)
  return LinearBezier
end)

SliderGenerator["CreateBezier"]=(
function (bezierPoints)
  local Bezier = Utilities.Copy(BezierFunctions)
  setmetatable(Bezier, SliderGenerator.CurveType)

  Bezier:create(bezierPoints)
  return Bezier
end)

SliderGenerator["CreateCatmull"]=(
function (sliderPoints, scaled, size)
  local Catmull = Utilities.Copy(CatmullFunctions)
  setmetatable(Catmull, SliderGenerator.EqualDistanceMultiCurve)

  Catmull:create(sliderPoints, scaled, size)
  return Catmull
end)

SliderGenerator["CreateCentripetalCatmullRom"]=(
function (catmullPoints)
  local CentripetalCatmullRom = Utilities.Copy(CentripetalCatmullRomFunctions)
  setmetatable(CentripetalCatmullRom, SliderGenerator.CurveType)

  CentripetalCatmullRom:create(catmullPoints)
  return CentripetalCatmullRom
end)

SliderGenerator["CreateCircumscribedCircle"]=(
function (sliderPoints, scaled, size)
  local CircumscribedCircle = Utilities.Copy(CircumscribedCircleFunctions)
  --setmetatable(CircumscribedCircle, SliderGenerator.CurveType)    Curve!

  CircumscribedCircle:create(sliderPoints, scaled, size)
  return CircumscribedCircle
end)

SliderGenerator["GetSliderCurve"]=(
function (sliderLineBlocks, scaled, sliderPoints)
  if sliderLineBlocks[6][1] == "P" and #sliderLineBlocks[6] == 3 then
    local nora = CreateVec2f():set(sliderPoints[2].x - sliderPoints[1].x, sliderPoints[2].y - sliderPoints[1].y):nor()
    local norb = CreateVec2f():set(sliderPoints[3].x - sliderPoints[2].x, sliderPoints[3].y - sliderPoints[2].y):nor()
    if (math.abs(norb.x * nora.y - norb.y * nora.x) < 0.00001) then
      --Linear Bezier
      return SliderGenerator.CreateLinearBezier(sliderPoints, false, scaled, sliderLineBlocks[8][1])
    else
      --Circumscribed Circle
      return SliderGenerator.CreateCircumscribedCircle(sliderPoints, scaled, sliderLineBlocks[8][1])
    end
  elseif sliderLineBlocks[6][1] == "C" and #sliderPoints ~= 2 then
    return SliderGenerator.CreateCatmull(sliderPoints, scaled, sliderLineBlocks[8][1])
  else
    --Linear Bezier
    return SliderGenerator.CreateLinearBezier(sliderPoints, sliderLineBlocks[6][1] == "L", scaled, sliderLineBlocks[8][1])
  end
end)

return SliderGenerator
