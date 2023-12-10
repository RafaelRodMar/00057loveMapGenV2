local Voronoi = require 'voronoi'
require 'perlinnoise'
local Graph = require 'graph'
require 'objectbutton'

--[[
	Dumps a table for inspection

	@param  table   table to inspect
	@param  mixed   table name [def: 1]
	@param  number  x starting position [def: 10]
	@param  number  y starting position [def: 10]
	@param  number  tab width [def: 20]
	@param  number  newLine height [def: 20]
	@param  mixed   number of newLines at EOL [def: 2]
	@return numbers x ending position, y ending position
--]]
function dumpTable(t, k, x, y, tab, NL, numNLatEOF)
	k = k or 1
	x = x or 10
	y = y or 10
	tab = tab or 20
	NL = NL or 20
	if numNLatEOF == nil then numNLatEOF = 2 end
	if type(k) == "number" then k = "[" .. k .. "]" end
	--love.graphics.print(k .. " = {", x, y)
    print(k .. " = {")
	x = x + tab
	y = y + NL
	for k,v in pairs(t) do
		if type(v) == "table" then
			x, y = dumpTable(v, k, x, y, tab, NL, false)
		else
			if v == true then v = "true"
				elseif v == false then v = "false"
				elseif type(v) == "string" then v = '"' .. v .. '"'
				elseif type(v) == "function" then v = "function"
				elseif type(v) == "userdata" then v = "userdata"
			end
			if type(k) == "number" then k = "[" .. k .. "]" end
			--love.graphics.print(k .. ' = ' .. v, x, y)
            print(k .. '=' .. v)
		end
		y = y + NL
	end
	x = x - tab
	--love.graphics.print("}", x, y)
    print("}")
	if numNLatEOF then y = y + NL * numNLatEOF end
	return x, y
end


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
    gameWidth = 940
    gameHeight = 480
    love.window.setMode(gameWidth, gameHeight, {resizable=false, vsync=false})
    love.graphics.setBackgroundColor(1,1,1) --white

    --load font
    font = love.graphics.newFont("sansation.ttf",15)
    love.graphics.setFont(font)

    vMouse = {x=0, y=0}
    vClicked = {x=-1, y = -1}

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

    -- set colors for land (seed point inside polygon) and sea (seed point outside poligon)
    for index,point in pairs(genvoronoi.points) do
        if isPointInPolygon(point.x, point.y, polygon) == false then
            colors[index] = {r=0, g=0, b=1}
        else
            colors[index] = {r=0.698, g=0.651, b=0.580}
        end
    end

    -- now let's create two graphs as stated in the Amit Patel's polygon map generator for games
    -- The first graph has nodes for each polygon and edges between adjacent polygons.
    --      It represents the Delaunay triangulation, which is useful for anything involving adjacency (such as pathfinding).
    -- The second graph has nodes for each polygon corner and edges between corners.
    --      It contains the shapes of the Voronoi polygons. It's useful for anything involving the shapes (such as rendering borders).
    -- Use example:
    -- local Graph = require("graph") -- Replace "graph" with the actual file/module name

    -- -- Creating an empty graph
    -- local myGraph = Graph.new()

    -- -- Adding nodes
    -- myGraph:add_node("A")
    -- myGraph:add_node("B")
    -- myGraph:add_node("C")

    -- -- Adding edges between nodes
    -- myGraph:add_edge("A", "B")
    -- myGraph:add_edge("B", "C")
    -- myGraph:add_edge("C", "A")

    -- -- Setting weights
    -- myGraph:set_weight("A", "B", 5)
    -- myGraph:set_weight("B", "C", 3)
    -- myGraph:set_weight("C", "A", 2)

    -- to get the number of Nodes in the graph: 
    -- local numNodes = 0
    -- for _ in myGraph:nodes() do
    --     numNodes = numNodes + 1
    -- end

    -- print("Number of nodes:", numNodes)

    polygonGraph = Graph.new()
    -- fill the first graph with polygons
    for index, poly in pairs(genvoronoi.polygons) do  -- polygons contains : points, edges, centroid, index 
        polygonGraph:add_node(index)
        polygonGraph[index] = {}
        polygonGraph[index].index = poly.index
        polygonGraph[index].points = poly.points -- voronoi corners
        polygonGraph[index].edges = poly.edges -- conections between corners
        polygonGraph[index].centroid = poly.centroid
        polygonGraph[index].seed = genvoronoi.points[index]
        polygonGraph[index].isWater = false -- true = lake or ocean, false = land
        polygonGraph[index].isOcean = false -- ocean or lake
        polygonGraph[index].isCoast = false -- land polygon touching an ocean
        polygonGraph[index].isBorder = false -- at the edge of screen
        polygonGraph[index].biome = "none" -- biome type
        polygonGraph[index].elevation = 0.0 -- 0.0-1.0
        polygonGraph[index].moisture = 0.0 -- 0.0-1.0
        polygonGraph[index].neighbors = {} -- the polygons touching this one

        -- set the water,land,lake.
        if colors[index].b == 1 then 
            polygonGraph[index].isWater = true
            polygonGraph[index].isOcean = true
        end

        -- fill the neighbors table.
        local neighbTable = genvoronoi:getNeighbors('all', poly.index) -- returns all the polygons data in a table.
        for i = 1, #neighbTable do
            table.insert(polygonGraph[index].neighbors, neighbTable[i].index) -- only take the index value
        end

        -- check if it's in the border.
        for i = 1, #poly.points do
            if poly.points[i] == 0 or poly.points[i] == 640 or poly.points[i] == 480 then
                polygonGraph[index].isBorder = true
                break
            end
        end
    end

    -- check all the nodes of the graph and set the coast
    for index, node in ipairs(polygonGraph) do
        if node.isWater == true then goto continue end
        for i = 1, #node.neighbors do
            if polygonGraph[node.neighbors[i]].isWater == true then
                node.isCoast = true
                goto continue
            end
        end
        ::continue::
    end
    

    -- create the edges between adjacent polygons
    -- polygonmap contains, for every polygon, a list of adjacent polygons.
    -- If the edge 1-2 exists then the 2-1 already exists.
    for pointindex,relationgroups in pairs(genvoronoi.polygonmap) do
        for badindex,adjacentindex in pairs(relationgroups) do
            polygonGraph:add_edge(pointindex,adjacentindex)
        end
    end

    -- cornerGraph = Graph.new()
    -- -- fill the second graph with polygon corners
    -- local extindex = 1 -- using a external index because genvoronoi.vertex lacks some elements.
    -- for index,vertex in pairs(genvoronoi.vertex) do
    --     cornerGraph:add_node(extindex)
    --     cornerGraph[extindex] = {}
    --     cornerGraph[extindex].x = vertex.x
    --     cornerGraph[extindex].y = vertex.y
    --     extindex = extindex + 1 
    -- end
    -- create the edges between adjacent corners (segments)
    -- segments table contains: type(number), startPoint(x,y), endPoint(x,y), done(boolean)

    -- public class Corner {
    -- public var index:int;
    
    -- public var point:Point;  // location
    -- public var ocean:Boolean;  // ocean
    -- public var water:Boolean;  // lake or ocean
    -- public var coast:Boolean;  // touches ocean and land polygons
    -- public var border:Boolean;  // at the edge of the map
    -- public var elevation:Number;  // 0.0-1.0
    -- public var moisture:Number;  // 0.0-1.0

    -- public var touches:Vector.<Center>;
    -- public var protrudes:Vector.<Edge>;
    -- public var adjacent:Vector.<Corner>;
    
    -- public var river:int;  // 0 if no river, or volume of water in river
    -- public var downslope:Corner;  // pointer to adjacent corner most downhill
    -- public var watershed:Corner;  // pointer to coastal corner, or null
    -- public var watershed_size:int;
    -- };

    -- public class Edge {
    -- public var index:int;
    -- public var d0:Center, d1:Center;  // Delaunay edge
    -- public var v0:Corner, v1:Corner;  // Voronoi edge
    -- public var midpoint:Point;  // halfway between v0,v1
    -- public var river:int;  // volume of water, or 0
    -- };


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

    polygonSelected = -1
end

function love.mousemoved( x, y, dx, dy, istouch )
    vMouse.x = x
    vMouse.y = y
end

function love.mousepressed(x,y,button, istouch, presses)
	if button == 1 then
        vClicked.x = x
        vClicked.y = y
        if vClicked.x >= 0 and vClicked.x < 640 and vClicked.y >= 0 and vClicked.y < 480 then
            local closestPointIndex = 1
            local closestDistance = math.huge

            for i, point in ipairs(genvoronoi.points) do
                local distance = math.sqrt((x - point.x)^2 + (y - point.y)^2)

                if distance < closestDistance then
                    closestDistance = distance
                    closestPointIndex = i
                end
            end

            polygonSelected = closestPointIndex
        end
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
    if vClicked.x >= 0 and vClicked.x < 640 and vClicked.y >= 0 and vClicked.y < 480 then
        love.graphics.print("Polygon Selected : " .. polygonSelected, 650, 200)
        love.graphics.print("  Corners : " .. #polygonGraph[polygonSelected].points, 650, 220)
        love.graphics.print("  Edges : " .. #polygonGraph[polygonSelected].edges, 650, 240)
        love.graphics.print("  Centroid(rounded) : " .. math.floor(polygonGraph[polygonSelected].centroid.x) .. "," .. math.floor(polygonGraph[polygonSelected].centroid.y), 650, 260)
        love.graphics.print("  Seed(rounded) : " .. math.floor(polygonGraph[polygonSelected].seed.x) .. "," .. math.floor(polygonGraph[polygonSelected].seed.y), 650, 280)
        if polygonGraph[polygonSelected].isWater == true then
            love.graphics.print("  Is water (ocean)", 650, 300)
        else
            love.graphics.print("  Is land", 650, 300)
        end
        love.graphics.print("  Neighbors: " .. #polygonGraph[polygonSelected].neighbors, 650, 320)
        if polygonGraph[polygonSelected].isCoast == true then
            love.graphics.print("  Is coast", 650, 340)
        else
            love.graphics.print("  Not coast", 650, 340)
        end
        if polygonGraph[polygonSelected].isBorder == true then
            love.graphics.print("  Is Border", 650, 360)
        else
            love.graphics.print("  Not Border", 650, 360)
        end
    end
    love.graphics.print("Mouse: " .. vMouse.x .. "," .. vMouse.y, 650, 160)
    love.graphics.print("Clicked: " .. vClicked.x .. "," .. vClicked.y, 650, 180)
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