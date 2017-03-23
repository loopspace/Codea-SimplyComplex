-- Utilities

--[[
This is for little bits of code that are needed by more than one class but
don't really belong to any one thing.
--]]

--[[
This is an auxilliary function for drawing a rectangle with possibly
curved cornders.  The first four parameters specify the rectangle.
The fifth is the radius of the corner rounding.  The optional sixth is
a way for specifying which corners should be rounded by passing a
number between 0 and 15.  The first bit corresponds to the lower-left
corner and it procedes clockwise from there.
--]]

local __RRects = {}

function RoundedRectangle(x,y,w,h,s,c,a)
    c = c or 0
    w = w or 0
    h = h or 0
    if w < 0 then
        x = x + w
        w = -w
    end
    if h < 0 then
        y = y + h
        h = -h
    end
    w = math.max(w,2*s)
    h = math.max(h,2*s)
    a = a or 0
    pushMatrix()
    translate(x,y)
    rotate(a)
    local label = table.concat({w,h,s,c},",")
    if __RRects[label] then
        __RRects[label]:setColors(fill())
        __RRects[label]:draw()
    else
    local rr = mesh()
    local v = {}
    local ce = vec2(w/2,h/2)
    local n = 4
    local o,dx,dy
    for j = 1,4 do
        dx = -1 + 2*(j%2)
        dy = -1 + 2*(math.floor(j/2)%2)
        o = ce + vec2(dx * (w/2 - s), dy * (h/2 - s))
        if math.floor(c/2^(j-1))%2 == 0 then
    for i = 1,n do
        table.insert(v,o)
        table.insert(v,o + vec2(dx * s * math.cos((i-1) * math.pi/(2*n)), dy * s * math.sin((i-1) * math.pi/(2*n))))
        table.insert(v,o + vec2(dx * s * math.cos(i * math.pi/(2*n)), dy * s * math.sin(i * math.pi/(2*n))))
    end
    else
        table.insert(v,o)
        table.insert(v,o + vec2(dx * s,0))
        table.insert(v,o + vec2(dx * s,dy * s))
        table.insert(v,o)
        table.insert(v,o + vec2(0,dy * s))
        table.insert(v,o + vec2(dx * s,dy * s))
    end
    end
    rr.vertices = v
    rr:addRect(ce.x,ce.y,w,h-2*s)
    rr:addRect(ce.x,ce.y + (h-s)/2,w-2*s,s)
    rr:addRect(ce.x,ce.y - (h-s)/2,w-2*s,s)
    rr:setColors(fill())
    rr:draw()
    __RRects[label] = rr
    end
    popMatrix()
end

--[[
Use the arc shader to draw an arc.
--]]

local __arc

local initarc = function()
    __arc = mesh()
    __arc:addRect(WIDTH/2,HEIGHT/2,200,200)
    __arc.shader = shader("Patterns:Arc")
    __arc.shader.a1 = 0
    __arc.shader.a2 = math.pi
    __arc.shader.size = .5 - 1/200
end

local doarc = function(...)
    local x,y,r,s,a,b,arg
    arg = {...}
    if #arg == 5 then
        x,y,r,a,b = unpack(arg)
    else
        x,r,a,b = unpack(arg)
        x,y = x.x,x.y
    end
    if a == b then
        return
    end
    s = strokeWidth()
    __arc:setRect(1,x,y,2*r+s,2*r+s)
    __arc.shader.a1 = a
    __arc.shader.a2 = b
    __arc.shader.size = 0.5 * (r-s/2)/(r+s/2)
    __arc.shader.color = color(stroke())
    __arc:draw()
end

function arc(...)
    initarc()
    doarc(...)
    arc = doarc
end

function Ordinal(n)
    local k = n%10
    local th = "th"
    if k == 1 then
        th = "st"
    elseif k == 2 then
        th = "nd"
    elseif k == 3 then
        th = "rd"
    end
    return n .. th
end
        


function USRotateCW(v)
    return ApplyAffine({vec2(0,-1),vec2(1,0),vec2(0,1)},v)
end

function USRotateCCW(v)
    return ApplyAffine({vec2(0,1),vec2(-1,0),vec2(1,0)},v)
end

function USReflectV(v)
    return ApplyAffine({vec2(-1,0),vec2(0,1),vec2(1,0)},v)
end

function USReflectH(v)
    return ApplyAffine({vec2(1,0),vec2(0,-1),vec2(0,1)},v)
end

USCoordinates = {}
USCoordinates[PORTRAIT] = {vec2(1,0),vec2(0,1),vec2(0,0)}
USCoordinates[PORTRAIT_UPSIDE_DOWN] = {vec2(-1,0),vec2(0,-1),vec2(1,1)}
USCoordinates[LANDSCAPE_LEFT] = {vec2(0,-1),vec2(1,0),vec2(0,1)}
USCoordinates[LANDSCAPE_RIGHT] = {vec2(0,1),vec2(-1,0),vec2(1,0)}

function USOrientation(o,v)
    return ApplyAffine(USCoordinates[o],v)
end

function getLength(l)
    local n = tonumber(l)
    if n then
        return n
    end
    local i,j,m,u = string.find(l,"^(%d*)(%D*)$")
    if i then
        if u == "px" or u == "pcx" then
            return m
        elseif u == "pt" then
            return m * 3.653
        elseif u == "in" then
            return m * 264
        elseif u == "cm" then
            return m * 670.56
        elseif u == "mm" then
            return m * 6705.6
        elseif u == "m" then
            return m * 67.056
        elseif u == "em" then
            local t = fontMetrics()
            return m * t.size
        elseif u == "en" then
            local t = fontMetrics()
            return m * t.size/2
        elseif u == "ex" then
            local t = fontMetrics()
            return m * t.xHeight
        elseif u == "lh" then
            local _,h = textSize("x")
            return m * h
        else
            return nil
        end
    end
    return nil
end

function evalLength(s)
    if type(s) == "function" then
        s = s()
    end
    s = string.gsub(s,"(%d+%a+)",
        function(n) return getLength(n) or n end)
    s = "local s = " .. s .. " return s"
    local f = loadstring(s)
    s = f()
    return s
end

Boolean = {}

function Boolean.readData(t,k,b)
    local f
    if t == "global" then
        f = readGlobalData
    elseif t == "project" then
        f = readProjectData
    else
        f = readLocalData
    end
    local bol = f(k)
    if bol then
        if bol == 0 then
            return false
        else
            return true
        end
    else
        return b
    end
end

function Boolean.saveData(t,k,b)
    local f
    if t == "global" then
        f = saveGlobalData
    elseif t == "project" then
        f = saveProjectData
    else
        f = saveLocalData
    end
    if b then
        f(k,1)
    else
        f(k,0)
    end
end
