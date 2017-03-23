-- Colour manipulation
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 (http://wiki.creativecommons.org/CC0)

--[[
This provides some functions for basic colour manipulation such as
colour blending.  The functions act on "color" objects and also return
"color" objects.
--]]

--[[
Although we are not a class, we work in the "Colour" namespace to keep
ourselves from interfering with other classes.
--]]

Colour = {}

-- Should we modify the alpha of our colours?
Colour.ModifyAlpha = false

--[[
This blends the two specified colours according to the parameter given
as the middle argument (the syntax is based on that of the "xcolor"
LaTeX package) which is the percentage of the first colour.
--]]

function Colour.blend(cc,t,c,m)
    local s,r,g,b,a
    m = m or Colour.ModifyAlpha
   s = t / 100
   r = s * cc.r + (1 - s) * c.r
   g = s * cc.g + (1 - s) * c.g
   b = s * cc.b + (1 - s) * c.b
   if m then
      a = s * cc.a + (1 - s) * c.a
   else
      a = cc.a
   end
   return color(r,g,b,a)
end

--[[
This "tints" the specified colour which means blending it with white.
The parameter is the percentage of the specified colour.
--]]

function Colour.tint(c,t,m)
   local s,r,g,b,a 
    m = m or Colour.ModifyAlpha
   s = t / 100
   r = s * c.r + (1 - s) * 255
   g = s * c.g + (1 - s) * 255
   b = s * c.b + (1 - s) * 255
   if m then
      a = s * c.a + (1 - s) * 255
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This "shades" the specified colour which means blending it with black.
The parameter is the percentage of the specified colour.
--]]

function Colour.shade(c,t,m)
   local s,r,g,b,a 
    m = m or Colour.ModifyAlpha
   s = t / 100
   r = s * c.r
   g = s * c.g
   b = s * c.b
   if m then
      a = s * c.a
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This "tones" the specified colour which means blending it with gray.
The parameter is the percentage of the specified colour.
--]]

function Colour.tone(c,t,m)
   local s,r,g,b,a 
    m = m or Colour.ModifyAlpha
   s = t / 100
   r = s * c.r + (1 - s) * 127
   g = s * c.g + (1 - s) * 127
   b = s * c.b + (1 - s) * 127
   if m then
      a = s * c.a + (1 - s) * 127
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This returns the complement of the given colour.
--]]

function Colour.complement(c,m)
    local r,g,b,a
        m = m or Colour.ModifyAlpha
   r = 255 - c.r
   g = 255 - c.g
   b = 255 - c.b
   if m then
      a = 255 - c.a
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
This forces each channel to an on/off state.
--]]

function Colour.posterise(c,t,m)
    local r,g,b,a
    m = m or Colour.ModifyAlpha
    t = t or 127
    if c.r > t then
        r = 255
    else
        r = 0
    end
    if c.g > t then
        g = 255
    else
        g = 0
    end
    if c.b > t then
        b = 255
    else
        b = 0
    end
   if m then
    if c.a > t then
        a = 255
    else
        a = 0
    end
   else
      a = c.a
   end
   return color(r,g,b,a)
end

--[[
These functions adjust the alpha.
--]]

function Colour.opacity(c,t)
    return color(c.r,c.g,c.b,t*c.a/100)
end

function Colour.opaque(c)
    return color(c.r,c.g,c.b,255)
end

--[[
This "pretty prints" the colour, converting it to a string.
--]]

function Colour.tostring(c)
    return "R:" .. c.r .. " G:" .. c.g .. " B:" .. c.b .. " A:" .. c.a
end

function Colour.fromstring(c)
    local r,g,b,a
    r = string.match(c,"R:(%d+)")
    g = string.match(c,"G:(%d+)")
    b = string.match(c,"B:(%d+)")
    a = string.match(c,"A:(%d+)")
    return color(r,g,b,a)
end

function Colour.readData(t,k,c)
    local f
    if t == "global" then
        f = readGlobalData
    elseif t == "project" then
        f = readProjectData
    else
        f = readLocalData
    end
    local col = f(k)
    if col then
        return Colour.fromstring(col)
    else
        return c
    end
end

function Colour.saveData(t,k,c)
    local f
    if t == "global" then
        f = saveGlobalData
    elseif t == "project" then
        f = saveProjectData
    else
        f = saveLocalData
    end
    f(k,Colour.tostring(c))
end

--[[
This searches for a colour by name from a specified list (such as
"svg" or "x11").  It looks for a match for the given string at the
start of the name of the colour, without regard for case.
--]]

function Colour.byName(t,n)
   local ln,k,v,s,lk
   ln = "^" .. string.lower(n)
   for k,v in pairs(Colour[t]) do
      lk = string.lower(k)
      s = string.find(lk,ln)
      if s then
         return v
      end
   end
   print("Colour Error: No colour of name " .. n .. " exists in type " .. t)
end

--[[
Get a random colour, either from a list or random.
But not black.
--]]

local __colourlists = {}

function Colour.random(s)
    if s then
        if __colourlists[s] then
            return __colourlists[s][math.random(#__colourlists[s])]
        elseif Colour[s] then
            __colourlists[s] = {}
            for k,v in pairs(Colour[s]) do
                if k ~= "Black" then
                    table.insert(__colourlists[s],v)
                end
            end
            return __colourlists[s][math.random(#__colourlists[s])]
        end
    end
    local r,g,b = 0,0,0
    while r+g+b < 20 do
        r,g,b = math.random(256)-1,
                math.random(256)-1,math.random(256)-1
    end
    return color(r,g,b,255)
end
            

--[[
The "ColourPicker" class is a module for the "User Interface" class
(though it can be used independently).  It defines a grid of colours
(drawn from a list) which the user can select from.  When the user
selects a colour then a "call-back" function is called with the given
colour as its argument.
--]]

ColourPicker = class()

--[[
There is nothing to do on initialisation.
--]]

function ColourPicker:init()
end

--[[
This is the real initialisation code, but it can be called at any
time.  It sets up the list from which the colours will be displayed
for the user to select from.  At the moment, it can deal with the
"x11" and "svg" lists, though allowing more is simple enough: the main
issue is deciding how many rows and columns to use to display the grid
of colours.
--]]

function ColourPicker:setList(t)
    local c,m,n
    if t == "x11" then
        -- 317 colours
        c = Colour.x11
        n = 20
        m = 16
    else
        -- 151 colours
        c = Colour.svg
        n = 14
        m = 11
    end
    local l = {}
    for k,v in pairs(c) do
        table.insert(l,v)
    end
    table.sort(l,ColourSort)
    self.m = m
    self.n = n
    self.colours = l
end

--[[
This is a crude sort routine for the colours.  It is not a good one.
--]]

function ColourSort(a,b)
    local c,d
    c = 2 * a.r + 4 * a.g + a.b
    d = 2 * b.r + 4 * b.g + b.b
    return c < d
end

--[[
This draws a grid of rounded rectangles (see the "Font" class) of each
colour.
--]]

function ColourPicker:draw()
    if self.active then
    pushStyle()
    strokeWidth(-1)
    local w = WIDTH/self.n
    local h = HEIGHT/self.m
    local s = math.min(w/4,h/4,10)
    local c = self.colours
    w = w - s
    h = h - s
    local i = 0
    local j = 1
    for k,v in ipairs(c) do
        fill(v)
        RoundedRectangle(s/2 + i*(w+s),HEIGHT + s/2 - j*(h+s),w,h,s)
        i = i + 1
        if i == self.n then
            i = 0
            j = j + 1
        end
    end
    popStyle()
    end
end

--[[
If we are active, we claim all touches.
--]]

function ColourPicker:isTouchedBy(touch)
    if self.active then
        return true
    end
end

--[[
The touch information is used to select a colour.  We wait until the
gesture has ended and then look at the xy coordinates of the first
touch.  This tells us which colour was selected and this is passed to
the call-back function which is stored as the "action" attribute.

The action attribute should be an anonymous function which takes one
argument, which will be a "color" object.
--]]

function ColourPicker:processTouches(g)
    if g.updated then
        if g.type.ended then
            local t = g.touchesArr[1]
            local w = WIDTH/self.n
            local h = HEIGHT/self.m
            local i = math.floor(t.touch.x/w) + 1
            local j = math.floor((HEIGHT - t.touch.y)/h)
            local n = i + j*self.n
            if self.colours[n] then
                if self.action then
                    local a = self.action(self.colours[n])
                    if a then
                        self:deactivate()
                    end
                end
            else
                self:deactivate()
            end
            g:reset()
        else
            g:noted()
        end
    end
end

--[[
This activates the colour picker, making it active and setting the
call-back function to whatever was passed to the activation function.
--]]

function ColourPicker:activate(f)
    self.active = true
    self.action = f
end

function ColourPicker:deactivate()
    self.active = false
    self.action = nil
end

ColourPicker.help = "The colour picker is used to choose a colour from a given range.  To choose a colour, touch one of the coloured rectangles.  You can cancel the colour picker by touching some part of the screen where there isn't a coloured rectangle (but where there would be one if there were more colours)."

ColourWheel = class()

function ColourWheel:init()
    self.meshsqr = mesh()
    self.meshhex = mesh()
    self.colour = color(255, 0, 0, 255)
    self.rimcolour = color(255, 0, 0, 255)
    local l = .9
    self.meshsqr.vertices = {
        l*vec2(1,1),
        l*vec2(-1,1),
        l*vec2(-1,-1),
        l*vec2(1,1),
        l*vec2(1,-1),
        l*vec2(-1,-1),
    }
    self.meshsqr.colors = {
        color(255, 255, 255, 255),
        self.rimcolour,
        color(0, 0, 0, 255),
        color(255, 255, 255, 255),
        Colour.complement(self.rimcolour,false),
        color(0, 0, 0, 255),
    }
    local t = {}
    local c = {}
    local cc = {
        color(255, 0, 0, 255),
        color(255, 255, 0, 255),
        color(0, 255, 0, 255),
        color(0, 255, 255, 255),
        color(0, 0, 255, 255),
        color(255, 0, 255, 255),
    }
    self.rimcolours = cc
    for i = 1,6 do
        table.insert(t,
            2*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            1.5*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            2*vec2(
                math.cos((i+1)*math.pi/3),
                math.sin((i+1)*math.pi/3)
                )
            )
        table.insert(t,
            2*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            1.5*vec2(
                math.cos(i*math.pi/3),
                math.sin(i*math.pi/3)
                )
            )
        table.insert(t,
            1.5*vec2(
                math.cos((i-1)*math.pi/3),
                math.sin((i-1)*math.pi/3)
                )
            )
        table.insert(c,cc[i])
        table.insert(c,cc[i])
        table.insert(c,cc[i%6+1])
        table.insert(c,cc[i])
        table.insert(c,cc[i])
        table.insert(c,cc[(i-2)%6+1])
    end
    self.meshhex.vertices = t
    self.meshhex.colors = c
    self.ratio = vec2(0,1)
    self.alpha = 255
    self:setRimColour(1,0)
end

function ColourWheel:setRimColour(x,y)
    self.angle = math.atan2(y,x)
    local a = 3*self.angle/math.pi
    local i = math.floor(a)+1
    a = 100*(i - a)
    i = (i-2)%6 + 1
    local j = i%6 + 1
    self.rimcolour = Colour.blend(
        self.rimcolours[i],a,self.rimcolours[j])
    self.meshsqr:color(2,self.rimcolour)
    self.meshsqr:color(5,Colour.complement(self.rimcolour,false))
    self:setColour()
end

function ColourWheel:setFromColour(rc)
    local c = color(rc.r,rc.g,rc.b,rc.a)
    self.alpha = c.a
    local x,y = math.min(c.r,c.g,c.b)/255,math.max(c.r,c.g,c.b)/255
    self.ratio = vec2(x,y)
    local i,j,ar
    if x == y then
        self.rimcolour = Colour.svg.Red
        self.angle = math.pi/3
    else
        c.r = (c.r - x*255)/(y - x)
        c.g = (c.g - x*255)/(y - x)
        c.b = (c.b - x*255)/(y - x)
        c.a = 255
        self.rimcolour = c
        ar = (c.r + c.g + c.b)/255 - 1
        if c.r >= c.g and c.r >= c.b then
            i = 1
            if c.g >= c.b then
                j = 2
            else
                j = 6
            end
        elseif c.g >= c.b then
            i = 3
            if c.b >= c.r then
                j = 4
            else
                j = 2
            end
        else
            i = 5
            if c.r >= c.g then
                j = 6
            else
                j = 4
            end
        end
        self.angle = (i*(1-ar) + ar*j)*math.pi/3
    end
    self.meshsqr:color(2,self.rimcolour)
    self.meshsqr:color(5,Colour.complement(self.rimcolour,false))
    self:setColour()
end

function ColourWheel:setColour()
    local x,y = self.ratio.x,self.ratio.y
    if y > x then
        self.colour = 
            Colour.shade(
                Colour.tint(
                    self.rimcolour,100*(1-x/y),false),100*y,false)
    elseif x > y then
        self.colour = 
            Colour.shade(
                Colour.tint(
                    Colour.complement(self.rimcolour,false)
                        ,100*(1-y/x),false),100*x,false)
    else
        self.colour = color(255*x,255*x,255*x,255)
    end
    self.colour.a = self.alpha
end

function ColourWheel:draw()
    if not self.active then
        return false
    end
    pushStyle()
    pushMatrix()
    resetMatrix()
    resetStyle()
    translate(WIDTH/2,HEIGHT/2)
    pushMatrix()

    scale(100)
    fill(71, 71, 71, 255)
    RoundedRectangle(-2.1,-3.1,4.6,5.2,.1)
    fill(Colour.opaque(self.colour))
    RoundedRectangle(-1.1,-2.9,2.2,.8,.1)
    self.meshsqr:draw()
    self.meshhex:draw()

    lineCapMode(SQUARE)
    strokeWidth(.05)
    --noSmooth()
    stroke(255, 255, 255, 255)
    line(2.05,self.alpha*3/255-1.5,2.35,self.alpha*3/255-1.5)
    stroke(127, 127, 127, 255)
    line(2.2,-1.55,2.2,1.55)
    stroke(Colour.complement(self.rimcolour,false))
    local a = self.angle - (math.floor(
            3*self.angle/math.pi) + .5)*math.pi/3
    local r = math.cos(math.pi/6)/math.cos(a)
    
    line(1.53*r*math.cos(self.angle),1.53*r*math.sin(self.angle),
        1.97*r*math.cos(self.angle),1.97*r*math.sin(self.angle))
    stroke(255, 255, 255, 255)
    noFill()
    noSmooth()
    popMatrix()
    strokeWidth(5)
    ellipseMode(RADIUS)
    ellipse(self.ratio.x*180-90,self.ratio.y*180-90,20)
    ellipse(220,self.alpha*300/255-150,20)
    fill(Colour.opaque(
            Colour.complement(
                Colour.posterise(self.colour,127,false),false
                )
            )
        )
    font("Courier-Bold")
    textMode(CENTER)
    fontSize(48)
    text("Select",0,-250)
    popMatrix()
    popStyle()
end

--[[
If we are active, we claim all touches.
--]]

function ColourWheel:isTouchedBy(touch)
    if self.active then
        return true
    end
end

--[[
The touch information is used to select a colour.  We wait until the
gesture has ended and then look at the xy coordinates of the first
touch.  This tells us which colour was selected and this is passed to
the call-back function which is stored as the "action" attribute.

The action attribute should be an anonymous function which takes one
argument, which will be a "color" object.
--]]

function ColourWheel:processTouches(g)
    if g.updated then
        local t = g.touchesArr[1]
        local x = (t.touch.x - WIDTH/2)/100
        local y = (t.touch.y - HEIGHT/2)/100
        if t.touch.state == BEGAN then
            if math.abs(x) < .9 and math.abs(y) < .9 then
                self.touchedon = 0
            elseif vec2(x,y):lenSqr() > 1 and vec2(x,y):lenSqr() < 4 then
                self.touchedon = 1
            elseif math.abs(x) < 1.1 and math.abs(y+2.5) < .4 then
                self.touchedon = 2
            elseif math.abs(x-2.2) < .1 and math.abs(y) < 1.6 then
                self.touchedon = 3
            elseif math.abs(x-.2) < 2.3 and math.abs(y+.5) < 2.6 then
                self.touchedon = 4
            else
                self.touchedon = 5
            end
        end
        if self.touchedon == 0 then
            x = math.min(math.max((x+.9)/1.8,0),1)
            y = math.min(math.max((y+.9)/1.8,0),1)
            self.ratio = vec2(x,y)
            self:setColour()
        end
        if self.touchedon == 1 then
            self:setRimColour(x,y)
        end
        if self.touchedon == 3 then
            self.alpha = math.min(math.max((y+1.5)*255/3,0),255)
            self:setColour()
        end
        if t.touch.state == ENDED then
            if self.touchedon == 5 then
                if math.abs(x) > 2.1 or math.abs(y+.5) > 2.6 then
                    self:deactivate()
                end
            elseif self.touchedon == 2 then
                if math.abs(x) < 1.1 and math.abs(y+2.5) < .4 then
                    local a = self.action(self.colour)
                    if a then
                        self:deactivate()
                    end
                end
            end
        end
        g:noted()
    end
    if g.type.ended then
        g:reset()
    end
end

--[[
This activates the colour wheel, making it active and setting the
call-back function to whatever was passed to the activation function.
--]]

function ColourWheel:activate(c,f)
    self.active = true
    if c then
        self:setFromColour(c)
    end
    self.action = f
end

function ColourWheel:deactivate()
    self.active = false
    self.action = nil
end

ColourWheel.help = "The colour wheel is used to choose a colour.  The outer wheel selects the dominant colour then the inner square allows you to blend it or its complement with white and black.  Click on the Select button to choose the colour or outside the wheel region to cancel the colour change."
