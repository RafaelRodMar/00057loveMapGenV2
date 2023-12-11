# 00057loveMapGenV2
Map generator made with Löve. Version 2.

See this site : http://www-cs-students.stanford.edu/~amitp/game-programming/polygon-map-generation/

voronoi.lua belongs to https://github.com/TomK32/iVoronoi
I did two changes to this library:
    
    First one (at the beginning): 

    -- sets up the rvoronoi events
    for i = 1,#rvoronoi[it].points do
        if rvoronoi[it].points[i].x == nil then goto continue end -- this prevents a error
        rvoronoi[it].events:push(rvoronoi[it].points[i], rvoronoi[it].points[i].x,{i} )
        ::continue::
    end

    Second one (at the getNeighbors function):

    -- builds a table of it input polygons
    local arg = {...}   -- this one for getting the parameters
    for i=2,#arg do 
        indexes[arg[i]] = true 
    end

The perlinnoise.lua file is from https://gist.github.com/kymckay/25758d37f8e3872e1636d90ad41fe2ed

The libraries class.lua, graph.lua, table_heap.lua and heap.lua belong to https://github.com/TheAlgorithms/Lua