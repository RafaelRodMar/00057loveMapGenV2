# 00057loveMapGenV2
Map generator made with Löve. Version 2.

See this site : http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/

voronoi.lua belongs to https://github.com/TomK32/iVoronoi
I did changes to this library:
    
    First one the function voronoilib.tools.polygon:new(inpoints, inindex) changed it for the version revised by ChatGPT.


    Second one (at the getNeighbors function):

    -- builds a table of it input polygons
    local arg = {...}   -- this one for getting the parameters
    for i=2,#arg do 
        indexes[arg[i]] = true 
    end

    Third one: in the iterations there were nil points causing indexing nil errors so i checked them
    before and restart (5 times) until no nil points are present:

    -- sets up the rvoronoi events
    -- check for nil points, 
    for i=1, #rvoronoi[it].points do
        if rvoronoi[it].points[i] == nil then 
            print("error: nil value found, restarting " .. restartattempts)
            restartattempts = restartattempts - 1
            if restartattempts == 0 then break end
            goto restartlabel
        end
    end 
    for i = 1,#rvoronoi[it].points do
        rvoronoi[it].events:push(rvoronoi[it].points[i], rvoronoi[it].points[i].x,{i} )
    end

The perlinnoise.lua file is from https://gist.github.com/kymckay/25758d37f8e3872e1636d90ad41fe2ed

The libraries class.lua, graph.lua, table_heap.lua and heap.lua belong to https://github.com/TheAlgorithms/Lua