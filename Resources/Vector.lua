--Taken from Opsu
--Used for x and y coordinates for slider points
function CreateVec2f()
  local Vec2f = {
    x, y,

    set=(
      function (self, nx, ny)
        self.x = nx
        self.y = ny
        return self
      end),

    midPoint=(
      function (self, o)
        return CreateVec2f():set((self.x + o.x)/2, (self.y + o.y)/2)
      end),

    scale=(
      function (self, s)
        self.x = self.x * s
        self.y = self.y * s
        return self
      end),

    addV=(
      function (self, o)
        self.x = self.x + o.x
        self.y = self.y + o.y
        return self
      end),

    subV=(
      function (self, o)
        self.x = self.x - o.x
        self.y = self.y - o.y
        return self
      end),

    nor=(
      function (self)
        local nx, ny = -self.y, self.x
        self.x = nx
        self.y = ny
        return self
      end),

    normalize=(
      function (self)
        local len = self:len()
        self.x = self.x / len
        self.y = self.y / len
        return self
      end),

    cpy=(
      function (self)
        return CreateVec2f():set(self.x, self.y)
      end),

    add=(
      function (self, nx, ny)
        self.x = self.x + nx
        self.y = self.y + ny
        return self
      end),

    len=(
      function (self)
        return math.sqrt(self.x * self.x + self.y * self.y)
      end),

    equals=(
      function (self, o)
        return ((self.x == o.x) and (self.y == o.y))
      end),

    toString=(
      function (self)
        return (self.x .. ", " .. self.y)
      end)
  }
  return Vec2f
end

return CreateVec2f
