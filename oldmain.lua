local Voronoi = require 'voronoi'
require 'perlinnoise'
local Graph = require 'graph'
require 'objectbutton'

-- interpret a value in a range as a value in other range
function map(value, start1, stop1, start2, stop2)
    return start2 + (stop2 - start2) * ((value - start1) / (stop1 - start1))
end

-- By Pedro Gimeno, donated to the public domain
function isPointInPolygon(x, y, poly)
    local x1, y1, x2, y2
    local len = #poly
    x2, y2 = poly[len - 1], poly[len]
    local wn = 0
    for idx = 1, len, 2 do
        x1, y1 = x2, y2
        x2, y2 = poly[idx], poly[idx + 1]

        if y1 > y then
            if (y2 <= y) and (x1 - x) * (y2 - y) < (x2 - x) * (y1 - y) then
                wn = wn + 1
            end
        else
            if (y2 > y) and (x1 - x) * (y2 - y) > (x2 - x) * (y1 - y) then
                wn = wn - 1
            end
        end
    end

    -- wn is the winding number (the number of times the polygon turns around 
    -- the given point). It allows you to choose what rule to use for considering 
    -- a point to be inside the polygon; see https://en.wikipedia.org/wiki/Even-odd_rule.
    -- RNavega used the even-odd rule, so I made mine compatible with that. But if you 
    -- prefer the non-zero winding rule, you can change it to wn ~= 0.
    -- return wn % 2 ~= 0 -- even/odd rule
    return wn ~= 0
end

function love.load()
    --variables
    gameWidth = 840
    gameHeight = 480
    love.window.setMode(gameWidth, gameHeight, {resizable=false, vsync=false})
    love.graphics.setBackgroundColor(1,1,1) --white

    --load font
    font = love.graphics.newFont("sansation.ttf",15)
    love.graphics.setFont(font)

    vMouse = {x=0, y=0}
    vClicked = {x=-1, y = -1}

    love.graphics.setPointSize(4)

    -- generate the voronoi diagram
    pointcount = 225 --15 * 15 --295

    -- create a table with random colors
    colors = {}

    for i = 1, pointcount do
        local col = {}
        col.r = math.random()
        col.g = math.random()
        col.b = math.random()
        table.insert(colors, col)
    end

    genvoronoi = Voronoi:new(pointcount,3,0,0,640,gameHeight)

    -- generate polygon (perlin noise)
    polygon = {}
    local perlin_TWOPI = 6.28318530718
    local noiseMax = 5  -- 0.1 is a circle, 150 is chaotic.
    for a=0, perlin_TWOPI, 0.1 do
        local xoff = map(math.cos(a), -1, 1, 0, noiseMax)
        local yoff = map(math.sin(a), -1, 1, 0, noiseMax)
        local r = map(perlin:noise(xoff,yoff),-1,1,100,250)
        local x = r * math.cos(a) + 640 / 2
        local y = r * math.sin(a) + gameHeight / 2
        table.insert(polygon, x)
        table.insert(polygon,y)
    end

    -- set colors for land / sea
    for index,point in pairs(genvoronoi.points) do
        if isPointInPolygon(point.x, point.y, polygon) == false then
            colors[index] = {r=0, g=0, b=1}
        end
    end

    -- create some buttons
    buttons = {}

    table.insert(buttons, objectbutton:new("showpolygons", "Hide polygons", 0, 650, 20))
    buttons[1].pressed = true
    table.insert(buttons, objectbutton:new("showsegments", "Hide segments", 0, 650, 40))
    buttons[2].pressed = true
    table.insert(buttons, objectbutton:new("showcorners", "Show corners", 0, 650, 60))
    table.insert(buttons, objectbutton:new("showseeds", "Show seeds", 0, 650, 80))
    table.insert(buttons, objectbutton:new("showcentroids", "Show centroids", 0, 650, 100))
    table.insert(buttons, objectbutton:new("showrelationshiplines", "Show relationship lines", 0, 650, 120))
    table.insert(buttons, objectbutton:new("polygon", "Show random polygon", 0, 650, 140))
    showpolygons = true
    showsegments = true
    showcorners = false
    showseeds = false
    showcentroids = false
    showrelationshiplines = false
    showrandompolygon = false
end

function love.mousemoved( x, y, dx, dy, istouch )
    vMouse.x = x
    vMouse.y = y
end

function love.mousepressed(x,y,button, istouch, presses)
	if button == 1 then
        vClicked.x = x
        vClicked.y = y
	end

    for i=1, #buttons do
        buttons[i]:mousepressed(x,y,button,istouch,presses)
    end
end

function love.update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(0.5,0.5,0.5)
    love.graphics.setColor(0,0,0)

    -- draw the voronoi diagram
    draw(genvoronoi)

    -- Draw Debug Info
    --draw UI
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", 640, 0, 840, 480)
    for i=1, #buttons do
        buttons[i]:draw()
    end
    love.graphics.setColor(1,0,0)
    love.graphics.print("Mouse: " .. vMouse.x .. "," .. vMouse.y, 650, 400)
    love.graphics.print("Clicked: " .. vClicked.x .. "," .. vClicked.y, 650, 420)
end

-- called from love.draw
function draw(ivoronoi)

	-- draws the polygons
    if showpolygons then
        for index,polygon in pairs(ivoronoi.polygons) do
            if #polygon.points >= 6 then
                love.graphics.setColor(colors[index].r,colors[index].g,colors[index].b)
                love.graphics.polygon('fill',unpack(polygon.points))
                love.graphics.setColor(255,255,255)
                love.graphics.polygon('line',unpack(polygon.points))
            end
        end
    end

	-- draws the segments
    if showsegments then
        love.graphics.setColor(150,0,100)
        for index,segment in pairs(ivoronoi.segments) do
            love.graphics.line(segment.startPoint.x,segment.startPoint.y,segment.endPoint.x,segment.endPoint.y)
        end
    end

	-- draws the segment's vertices (corners)
    if showcorners then
        love.graphics.setColor(250,100,200)
        love.graphics.setPointSize(5)
        for index,vertex in pairs(ivoronoi.vertex) do
            love.graphics.points(vertex.x,vertex.y)
        end
    end

	-- draw the points (seeds)
    if showseeds then
        love.graphics.setColor(0,0,0)
        love.graphics.setPointSize(7)
        for index,point in pairs(ivoronoi.points) do
            love.graphics.points(point.x,point.y)
            love.graphics.print(index,point.x,point.y)
        end
    end

	-- draws the centroids
    if showcentroids then
        love.graphics.setColor(255,255,0)
        love.graphics.setPointSize(5)
        for index,point in pairs(ivoronoi.centroids) do
            love.graphics.points(point.x,point.y)
            love.graphics.print(index,point.x,point.y)
        end
    end

	-- draws the relationship lines
    if showrelationshiplines then
        love.graphics.setColor(0,255,0)
        for pointindex,relationgroups in pairs(ivoronoi.polygonmap) do
            for badindex,subpindex in pairs(relationgroups) do
                love.graphics.line(ivoronoi.centroids[pointindex].x,ivoronoi.centroids[pointindex].y,ivoronoi.centroids[subpindex].x,ivoronoi.centroids[subpindex].y)
            end
        end
    end

    -- draw a random polygon
    if showrandompolygon then
        love.graphics.polygon("line", polygon)
    end
end