objectbutton = {}

objectbutton_mt = { __index = objectbutton }

function objectbutton:new(name, text, callback, x, y)
    local entity = {}
    setmetatable(entity, objectbutton_mt)

    entity.name = name
    entity.text = text
    entity.posx = x
    entity.posy = y
    entity.width = font:getWidth(text) + 5
    entity.height = font:getHeight(text) + 2
    entity.callback = callback
    entity.pressed = false

    return entity
end

function objectbutton:mousepressed(x, y, button, istouch, presses)
    if x > self.posx and x < self.posx + self.width + 5 and
        y > self.posy and y < self.posy + self.height then
            if self.name == "showpolygons" then showpolygons = not showpolygons end
            if self.name == "showsegments" then showsegments = not showsegments end
            if self.name == "showcorners" then showcorners = not showcorners end
            if self.name == "showseeds" then showseeds = not showseeds end
            if self.name == "showcentroids" then showcentroids = not showcentroids end
            if self.name == "showrelationshiplines" then showrelationshiplines = not showrelationshiplines end
            if self.name == "polygon" then showrandompolygon = not showrandompolygon end
            self.pressed = not self.pressed
    end
end

function objectbutton:update(dt)
end

function objectbutton:draw()
    local text = ""
    if self.pressed == false then
        love.graphics.setColor(0.5,0.5,0.5)
        text = "Show " .. string.sub(self.text,5)
        self.width = font:getWidth(text) + 5
    else
        love.graphics.setColor(0,1,0)
        text = "Hide " .. string.sub(self.text,5)
        self.width = font:getWidth(text) + 5
    end
    love.graphics.rectangle("fill", self.posx, self.posy, self.width, self.height)
    love.graphics.setColor(0,0,0)
    love.graphics.print(text, self.posx + 2, self.posy + 2)
    love.graphics.setColor(1,1,1)
end