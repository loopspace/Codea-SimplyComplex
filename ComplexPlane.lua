-- Complex plane class
-- Author: Andrew Stacey
-- Website: http://www.math.ntnu.no/~stacey/HowDidIDoThat/iPad/Codea.html
-- Licence: CC0 http://wiki.creativecommons.org/CC0

ComplexPlane = class()

function ComplexPlane:init(f,ui,t)
    
    Complex.symbol = readLocalData("symbol","i")
    local radeg = readLocalData("angle","rad")
    if radeg == "rad" then
        Complex.angle = 1
        Complex.angsym = "π"
    else
        Complex.angle = 180
        Complex.angsym = "°"
    end
    Complex.precision = readLocalData("precision",1)
    
    self.font = f
    self.lfont = f:clone()
    self.points = {}
    self.bgcolour = Colour.readData("local", "bgcolour", Colour.svg.LightGrey)
    self.axescolour = Colour.readData("local", "axescolour",Colour.svg.DarkSlateBlue)
    self.controlcolour = Colour.readData("local", "controlcolour", Colour.svg.Salmon)
    self.ptcolour = Colour.readData("local", "ptcolour", Colour.svg.DarkRed)
    self.cptcolour = Colour.readData("local", "cptcolour", Colour.svg.Green)
    self.textcolour = Colour.readData("local", "textcolour", Colour.svg.DeepPink)
    self.veccolour = Colour.readData("local","veccolour",Colour.svg.Black)
    self.labcolour = Colour.readData("local","labcolour",Colour.svg.DimGrey)
    self.font:setColour(self.textcolour)
    self.lfont:setColour(self.labcolour)
    self.scale = HEIGHT/4
    self.lh = f:lineheight()
    self.showvalue = Boolean.readData("local","showvalue",true)
    self.showvec = Boolean.readData("local","showvec",true)
    self.polar = Boolean.readData("local","polar",false)
    self.fullscreen = Boolean.readData("local","fullscreen",false)
    self.splitscreen = Boolean.readData("local","splitscreen",false)
    self.op = ComplexPlane.operations["None"]
    self.drawVectors = ComplexPlane.drawLines["None"]
    self.language = readLocalData("language","English")

    self.helptext = Textarea({
        font = Font({name = "Courier", size = "12"}),
        pos = function()
                    local x,y = RectAnchorOf(Screen,"east")
                    return x+5,y
                end,
        width = WIDTH - math.min(WIDTH,HEIGHT)-10,
        height = HEIGHT/2,
        anchor = "north east",
        --fit = true,
        title = self:getString("Help"),
        valign = "top",
        colour = Colour.transparent
        })
    self.helptext:disableTouches()
    ui:addElement(self.helptext)

    self.plane = {0,0,math.min(WIDTH,HEIGHT),math.min(WIDTH,HEIGHT)}
    self.helptext:activate()
    
    local startMessage = Boolean.readData("local","startMessage",true)
    if startMessage then
    local info = Textarea({
        font = Font({name = "Courier", size = "30"}),
        pos = function()
                    local x,y = RectAnchorOf(self.plane,"centre")
                    return x+5,y
                end,
        width = RectAnchorOf(self.plane,"width") - 20,
        height = HEIGHT,
        anchor = "centre",
        fit = true,
        valign = "top",
        colour = Colour.svg.RosyBrown,
        textColour = Colour.svg.LemonChiffon
        })
    ui:addElement(info)
    info:setLines(unpack(self:getString("Intro")))
    info:activate()
    info:disableTouches()
    t.interrupt = self
    self.interruption = function(self,touch)
        info:deactivate()
        t.interrupt = nil
        return true
    end
    Boolean.saveData("local","startMessage",false)
    end
    
    self.o = vec2(RectAnchorOf(self.plane,"centre"))
    local menuOpts = {
            pos = function()
                local x,y = RectAnchorOf(self.plane,"north east")
                return x+2,y-5
            end,
            anchor = "north west",
            autoactive = false,
            minWidth = WIDTH - math.min(WIDTH,HEIGHT)-14,
            colour = Colour.svg.DimGrey,
            textColour = Colour.svg.Linen
        }
    local m = ui:addMenu({
        menuOpts = menuOpts
    })

    m:activate()
    self.mainmenu = m
    menuOpts.onActivation = function() m.active = false self:setHelpText("OperationHelp") end
    menuOpts.onDeactivation = function() m.active = true end
    menuOpts.autoactive = true

    local om = ui:addMenu({
        menuOpts = menuOpts
    })
    menuOpts.onActivation = function() m.active = false self:setHelpText("CustomHelp") end
    menuOpts.onDeactivation = function() m.active = true self:setHelpText("MainHelp") end
    local cm = ui:addMenu({
        menuOpts = menuOpts
    })
    menuOpts.onActivation = function() m.active = false self:setHelpText("ConstrainHelp") end
    local ctm = ui:addMenu({
        menuOpts = menuOpts
    })
    menuOpts.onActivation = function() m.active = false self:setHelpText("ColourHelp") end
    local clm = ui:addMenu({
        menuOpts = menuOpts
    })
    menuOpts.minWidth = nil
    menuOpts.onActivation = nil
    menuOpts.anchor = "north east"
    local fm = ui:addMenu({
        menuOpts = menuOpts
    })
    self.fsMenu = fm
    fm:addItem({
        title = "X",
        action = function()
            self:setSplitscreen(false)
            self:setFullscreen(false)

        end
    })
    local opit = m:addItem({
                  title = self:getString("ChooseOperation"),
        action = function(x,y)
            om:toggle()
        end,
        highlight = function()
            return om.active
        end,
        deselect = function()
            om:deactivateDown()
        end
    })
    m:addItem({
         title = self:getString("ResetShiftScale"),
        action = function()
            self.scale = HEIGHT/4
            self.o = vec2(RectAnchorOf(self.plane,"centre"))
            return true
        end
    })
    m:addItem({
         title = self:getString("ControlPointOrigin"),
        action = function()
            self.controlpt = Complex(0,0)
            return true
        end
    })
    m:addItem({
         title = self:getString("SinglePoint"),
        action = function()
            self.singleton = not self.singleton
            Boolean.saveData("local", "singleton", self.singleton)
            if self.singleton then
                self.points = { table.remove(self.points)}
            end
            return true
        end,
        highlight = function()
            return self.singleton
        end    
    })

    local cpit = m:addItem({
                  title = self:getString("ConstrainControl"),
        action = function(x,y)
            ctm:toggle()
        end,
        highlight = function()
            return ctm.active
        end,
        deselect = function()
            ctm:deactivateDown()
        end
    })
    m:addItem({
         title = self:getString("ClearPoints"),
        action = function()
            self:clear()
            return true
        end
    })
    m:addItem({
         title = self:getString("ShowValues"),
        action = function()
            self.showvalue = not self.showvalue
            Boolean.saveData("local","showvalue",self.showvalue)
            return true
        end,
        highlight = function()
            return self.showvalue
        end
    })
    m:addItem({
         title = self:getString("ShowVectors"),
        action = function()
            self.showvec = not self.showvec
            Boolean.saveData("local","showvec",self.showvec)
            return true
        end,
        highlight = function()
            return self.showvec
        end
    })
    m:addItem({
         title = self:getString("PolarForm"),
        action = function()
            self.polar = not self.polar
            Boolean.saveData("local","polar",self.polar)
            return true
        end,
        highlight = function()
            return self.polar
        end
    })
    m:addItem({
         title = self:getString("Customise"),
        action = function(x,y)
            cm:toggle()
        end,
        highlight = function()
            return cm.active
        end,
        deselect = function()
            cm:deactivateDown()
        end
    })
    m:addItem({
        title = self:getString("Fullscreen"),
        action = function()
            self:setFullscreen(true)
        end
    })
    m:addItem({
        title = self:getString("Splitscreen"),
        action = function()
            self:setFullscreen(true)
            self:setSplitscreen(true)
        end
    })
    self.demoit = m:addItem({
        title = self:getString("RunDemo"),
        action = function()
                self.demo:start()
            end
    })
    if not EXPORTED then
        m:addItem({
             title = self:getString("Exit"),
            action = function(x,y)
                close()
            end
        })
    end
    om:addItem({
          title = self:getString("ChooseOperation")
        })
    om:addItem({
          title = self:getString("None"),
        action = function()
       self.op = self.operations["None"]
       self.drawVectors = ComplexPlane.drawLines["None"]
       opit.title:setString(self:getString("ChooseOperation"))
       self.control = nil
       return true
        end,
        highlight = function()
       return self.op == ComplexPlane.operations["None"]
        end
        })
    for k,v in ipairs({
             {"Addition",true},
             {"Multiplication",true},
             {"Reciprocal",false},
             {"Conjugate",false},
             {"Minus",false},
             {"Exponential",true},
                    }) do
        om:addItem({
              title = self:getString(v[1]),
        action = function()
       self.op = ComplexPlane.operations[v[1]]
       self.drawVectors = ComplexPlane.drawLines[v[1]]
       opit.title:setString(self:getString(v[1]))
       self:setHelpText(v[1] .. "Help")
       self.control = v[2]
       return true
        end,
        highlight = function()
       return self.op == ComplexPlane.operations[v[1]]
        end
        })
    end
    om:addItem({
          title = self:getString("Roots"),
        action = function()
       self.op = ComplexPlane.operations["Roots"]
       self.drawVectors = ComplexPlane.drawLines["Roots"]
       ui:getNumberSpinner({
                  action = function(t)
                     t = tonumber(t)
                     self.root = math.floor(math.abs(t))
                     self:setHelpText("RootsHelp")
                     return true
                  end,
                  maxdigits = 1,
                  maxdecs = 0,
                  allowSignChange = false,
                value = self.root
                   }
                  )
       opit.title:setString(self:getString("Roots"))
       self:setHelpText("RootsChoose")
       self.control = false
       return true
        end,
        highlight = function()
       return self.op == ComplexPlane.operations["Roots"]
        end
    })
    om:addItem({
          title = self:getString("MainMenu"),
        action = function(x,y)
            om:deactivate()
        end
    })
    cm:addItem({
          title = self:getString("Customise")
    })
    cm:addItem({
          title = self:getString("PointSize"),
        action = function()
            self:setHelpText("PointSizeHelp")
            ui:getParameter(self.radius,
                1,
                50,
                function(t)
                    saveLocalData("radius",t)
                    self.radius = t
                end,
                function()
                    self:setHelpText("CustomHelp")
                end
            )
            -- return true
        end
    })
    local ijit
    ijit = cm:addItem({
        title = "",
        action = function()
            if Complex.symbol == "i" then
                Complex.symbol = "j"
                ijit.title:setString("√-1 = j")
            else
                Complex.symbol = "i"
                ijit.title:setString("√-1 = i")
            end
            saveLocalData("symbol",Complex.symbol)
            -- return true
        end
    })
    if Complex.symbol == "i" then
        ijit.title:setString("√-1 = i")
    else
        ijit.title:setString("√-1 = j")
    end
    local anit
    anit = cm:addItem({
        title = "",
        action = function()
            if Complex.angle == 1 then
                Complex.angle = 180
                Complex.angsym = "°"
                saveLocalData("angle","deg")
                anit.title:setString(self:getString("AnglesDegrees"))
            else
                Complex.angle = 1
                Complex.angsym = "π"
                saveLocalData("angle","rad")
                anit.title:setString(self:getString("AnglesRadians"))
            end
            -- return true
        end
    })
    if Complex.angle == 1 then
       anit.title:setString(self:getString("AnglesRadians"))
    else
       anit.title:setString(self:getString("AnglesDegrees"))
    end
    cm:addItem({
          title = self:getString("PrecisionValues"),
        action = function()
            self:setHelpText("PrecisionHelp")
       ui:getNumberSpinner({
                  action = function(t)
                     t = tonumber(t)
                     Complex.precision = math.floor(math.abs(t))
                    saveLocalData("precision",t)
                    self:setHelpText("CustomHelp")
                     return true
                  end,
                  maxdigits = 1,
                  maxdecs = 0,
                  allowSignChange = false,
                value = Complex.precision
                   }
                  )
            -- return true
        end
    })
    cm:addItem({
         title = self:getString("CustomiseColours"),
        action = function(x,y)
            clm:toggle()
            cm.active = not clm.active
        end,
        highlight = function()
            return clm.active
        end,
        deselect = function()
            clm:deactivateDown()
        end
    })
    cm:addItem({
          title = self:getString("ResetData"),
        action = function(x,y)
    self.bgcolour = Colour.svg.LightGrey
    self.axescolour = Colour.svg.DarkSlateBlue
    self.controlcolour = Colour.svg.Salmon
    self.ptcolour = Colour.svg.DarkRed
    self.cptcolour = Colour.svg.Green
    self.textcolour = Colour.svg.DeepPink
    self.veccolour = Colour.svg.Black
    self.labcolour = Colour.svg.DimGrey
    self.font:setColour(self.textcolour)
    self.lfont:setColour(self.labcolour)
    self.scale = HEIGHT/4
    self.showvalue = true
    self.showvec = true
    self.polar = false
    self.fullscreen = false
    self.op = ComplexPlane.operations["None"]
    self.drawVectors = ComplexPlane.drawLines["None"]
    self.language = readLocalData("language","English")
    self.o = vec2(RectAnchorOf(self.plane,"centre"))
            clearLocalData()
        end
    })
    cm:addItem({
          title = self:getString("MainMenu"),
        action = function(x,y)
            return true
        end
    })
    for k,v in ipairs({
    {"BackgroundColour", "bgcolour"},
    {"AxesColour", "axescolour"},
    {"ControlPointColour", "controlcolour"},
    {"PointColour", "ptcolour"},
    {"ComputedPointColour", "cptcolour"},
    {"VectorColour","veccolour"}
    }) do
        clm:addItem({
              title = self:getString(v[1]),
            action = function()
                ui:getColour(
                self[v[2]],
                function(c)
                    self[v[2]]= c
                    Colour.saveData("local",v[2],c)
                    return true
                end
            )
            -- return true
        end
        })
    end
    clm:addItem({
          title = self:getString("TextColour"),
            action = function()
                ui:getColour(
                self.textcolour,
                function(c)
                    self.textcolour= c
                    Colour.saveData("local","textcolour",c)
                    self.font:setColour(self.textcolour)
                    return true
                end
            )
            -- return true
        end
        })
    clm:addItem({
          title = self:getString("LabelColour"),
            action = function()
                ui:getColour(
                self.labcolour,
                function(c)
                    self.labcolour= c
                    Colour.saveData("local","labcolour",c)
                    self.lfont:setColour(self.labcolour)
                    return true
                end
            )
            -- return true
        end
        })
    clm:addItem({
          title = self:getString("MainMenu"),
        action = function(x,y)
            return true
        end
    })
    ctm:addItem({
           title = self:getString("ConstrainControl")
    })
    ctm:addItem({
           title = self:getString("None"),
        action = function()
            self.ctrlcond = function(z)
                return z
            end
            self.ctrlname = "None"
            cpit.title:setString(self:getString("None"))
            return true
        end,
        highlight = function()
            return self.ctrlname == "None"
        end
    })
    ctm:addItem({
           title = self:getString("RealAxis"),
        action = function()
            self.ctrlcond = function(z)
                z.z.y = 0
                return z
            end
            self.ctrlname = "Real"
            cpit.title:setString(self:getString("RealAxis"))
            return true
        end,
        highlight = function()
            return self.ctrlname == "Real"
        end
    })
    ctm:addItem({
           title = self:getString("ImaginaryAxis"),
        action = function()
            self.ctrlcond = function(z)
                z.z.x = 0
                return z
            end
            self.ctrlname = "Imaginary"
            cpit.title:setString(self:getString("ImaginaryAxis"))
            return true
        end,
        highlight = function()
            return self.ctrlname == "Imaginary"
        end
    })
    ctm:addItem({
           title = self:getString("UnitCircle"),
        action = function()
            self.ctrlcond = function(z)
                if z:is_zero() then
                    return Complex(1,0)
                else
                    return z:normalise()
                end
            end
            cpit.title:setString(self:getString("UnitCircle"))
            self.ctrlname = "Unit"
            return true
        end,
        highlight = function()
            return self.ctrlname == "Unit"
        end
    })
    ctm:addItem({
           title = self:getString("GaussianInteger"),
        action = function()
            self.ctrlcond = function(z)
                z.z.x = math.floor(z.z.x + .5)
                z.z.y = math.floor(z.z.y + .5)
                return z
            end
            self.ctrlname = "Gauss"
            cpit.title:setString(self:getString("GaussianInteger"))
            return true
        end,
        highlight = function()
            return self.ctrlname == "Gauss"
        end
    })
    ctm:addItem({
           title = self:getString("MainMenu"),
        action = function(x,y)
            ctm:deactivate()
        end
    })
    
    self.control = false
    self.controlpt = Complex(0,0)
    self.ctrlcond = function(z) return z end
    self.ctrlname = "None"
    self.radius = readLocalData("radius",4)
    self.controlr = readLocalData("controlr",20)
    self.root = 4
    self.singleton = Boolean.readData("local", "singleton", false)
    t:pushHandler(self)
    self:setHelpText("MainHelp")
    self:defineDemo(ui,opit)
    self:setFullscreen(self.fullscreen)
    self.restoreScreen = function() end
    self:setSplitscreen(self.splitscreen)
end

function ComplexPlane:setHelpText(s)
    s = self:getString(s)
    self.helptext:setLines(unpack(s))
end

function ComplexPlane:draw()
    self.demo:draw()
    local o = self.o
    local sh = self.shifts[#self.shifts]
    local x
    local s = self.scale
    if self.splitscreen then
        background(Colour.svg.Maroon)
        fill(self.bgcolour)
        for k,v in ipairs(self.shifts) do
            RoundedRectangle(v.x+5,v.y+5,RectAnchorOf(self.plane,"width")-10,RectAnchorOf(self.plane,"height")-10,5)
        end
    else
        background(self.bgcolour)
    end

    local east,south = RectAnchorOf(self.plane,"south east")
    local west,north = RectAnchorOf(self.plane,"north west")
    for k,v in ipairs(self.shifts) do
        stroke(self.axescolour)
        strokeWidth(8)
        line(v.x+o.x,v.y+south,v.x+o.x,v.y+north)
        line(v.x+east,v.y+o.y,v.x+west,v.y+o.y)
        strokeWidth(3)
        noFill()
        ellipseMode(RADIUS)
        ellipse(v.x+o.x,v.y+o.y,s)
        self.font:write("1",v.x+o.x+s,v.y+o.y+5)
        self.font:write(Complex.symbol,v.x+o.x+5,v.y+o.y + s)
        self.font:write("-1",v.x+o.x-s-24,v.y+o.y+5)
        self.font:write("-" .. Complex.symbol,v.x+o.x+5,v.y+o.y - s - self.lh/2)
    end
    fill(self.ptcolour)
    noStroke()
    noSmooth()
    local r = self.radius
    local n
    clipRect(self.plane)
    for k,v in ipairs(self.points) do
        x = s * v.z + o
        ellipse(x.x,x.y,r)
        n = k
    end
    clip()
    if self.op then
        fill(self.cptcolour)
        clipRect(shiftRect(self.plane,sh))
        local t
        for k,v in ipairs(self.points) do
            t = self.op(self,v)
            for l,w in ipairs(t) do
                x = s * w.z + o + sh
                ellipse(x.x,x.y,r)
            end
        end
        clip()
    end
    if self.control then
        fill(self.controlcolour)
        x = s * self.controlpt.z + o
        ellipse(x.x,x.y,self.controlr)
    end
    if self.showvec and n then
       self:drawVectors(self.points[n])
    end
    if self.showvalue and n then
        local z = self.points[n]
        x = s * z.z + o
        local st
        if self.polar then
            st = z:topolarstring()
        else
            st = z:tostring()
        end
        self.font:write(st,x.x,x.y)
        if self.op then
            local t = self:op(z)
            for l,w in ipairs(t) do
                x = s * w.z + o + sh
                if self.polar then
                    st = w:topolarstring()
                else
                    st = w:tostring()
                end
                self.font:write(st,x.x,x.y)
            end
        end
        if self.control then
            x = s * self.controlpt.z + o
            local st
            if self.polar then
                st = self.controlpt:topolarstring()
            else
                st = self.controlpt:tostring()
            end
            self.font:write(st,x.x,x.y)
        end
    end
    if not self.fullscreen then
        noSmooth()
        noStroke()
        rectMode(CORNERS)
        fill(Colour.svg.Maroon)
        rect(east,0,WIDTH,HEIGHT)
        fill(Colour.svg.DimGrey)
        RoundedRectangle(east+2,2,WIDTH-east-4,HEIGHT-4,15)
    end
end

function ComplexPlane:setFullscreen(b)
    self.fullscreen = b
    Boolean.saveData("local","fullscreen",b)
    if b then
        self.mainmenu:deactivate(true)
        self.helptext:deactivate()
        self.plane = {0,0,WIDTH,HEIGHT}
        self.fsMenu:orientationChanged()
        self.fsMenu:activate()
    else
        self.mainmenu:activate()
        self.helptext:activate()
        self.plane = {0,0,math.min(WIDTH,HEIGHT),math.min(WIDTH,HEIGHT)}
        self.mainmenu:orientationChanged()
        self.fsMenu:deactivate()
        self.splitscreen = false
    end
    self.o = vec2(RectAnchorOf(self.plane,"centre"))
end

function ComplexPlane:setSplitscreen(b)
    self.splitscreen = b
    Boolean.saveData("local","splitscreen",b)
    if b then
        if RectAnchorOf(self.plane,"width") > RectAnchorOf(self.plane,"height") then
            self.plane = {0,0,RectAnchorOf(self.plane,"width")/2,RectAnchorOf(self.plane,"height")}
            self.o.x = self.o.x/2
            self.shifts = {vec2(0,0),vec2(RectAnchorOf(self.plane,"width"),0)}
            self.restoreScreen = function()
                self.plane = {0,0,RectAnchorOf(self.plane,"width")*2,RectAnchorOf(self.plane,"height")}
                self.o.x = self.o.x*2
            end
        else
            self.plane = {0,0,RectAnchorOf(self.plane,"width"),RectAnchorOf(self.plane,"height")/2}
            self.o.y = self.o.y/2
            self.shifts = {vec2(0,0),vec2(0,RectAnchorOf(self.plane,"height"))}
            self.restoreScreen = function()
                self.plane = {0,0,RectAnchorOf(self.plane,"width"),RectAnchorOf(self.plane,"height")*2}
                self.o.y = self.o.y*2
            end
        end
    else
        self:restoreScreen()
        self.restoreScreen = function() end
        self.shifts = {vec2(0,0)}
    end
end

function ComplexPlane:clear()
    self.points = {}
end

ComplexPlane.operations = {
   None = function (self,v)
      return {}
   end,
   Addition = function (self,v)
      return {v + self.controlpt}
   end,
   Multiplication = function (self,v)
      return {v * self.controlpt}
   end,
   Reciprocal = function (self,v)
      if not v:is_zero() then
     return {v:reciprocal()}
      else
     return {}
      end
   end,
   Minus = function (self,v)
      return {-v}
   end,
   Conjugate = function (self,v)
      return {v^""}
   end,
   Exponential = function (self,v)
      if not v:is_zero() then
     return {v^self.controlpt}
      else
     return {}
      end
   end,
   Roots = function (self,v)
      local s = {}
      local n = 1/self.root
      for i = 1,self.root do
     table.insert(s,v:power(n,i))
      end
      return s
   end
}

function ComplexPlane:drawCartesian(z,sc)
    sc = sc or 1
    local sh = self.shifts[(sc-1)%#self.shifts+1]
   local s,o = self.scale, self.o + sh
   local v = s * z.z
   local x = v + o
   stroke(self.veccolour)
   line(o.x,o.y,x.x,x.y)
   v = 10*v:normalize()
   line(x.x,x.y,x.x - 2*v.x + v.y,x.y - 2*v.y - v.x)
   line(x.x,x.y,x.x - 2*v.x - v.y,x.y - 2*v.y + v.x)
   if self.showvalue then
      line(x.x,o.y,x.x,x.y)
      line(o.x,x.y,x.x,x.y)
      local st = math.floor(
     z:real() * 10^Complex.precision +.5
             )/10^Complex.precision
      self.lfont:write(st,x.x,o.y)
      st = math.floor(
     z:imaginary() * 10^Complex.precision +.5
             )/10^Complex.precision
      self.lfont:write(st,o.x,x.y)
   end
end

function ComplexPlane:drawPolar(z,sc)
    sc = sc or 1
    local sh = self.shifts[(sc-1)%#self.shifts+1]
   local s,o = self.scale, self.o + sh
   local v = s * z.z
   local x = v + o

   stroke(self.veccolour)
   line(o.x,o.y,x.x,x.y)
   v = 10*v:normalize()
   line(x.x,x.y,x.x - 2*v.x + v.y,x.y - 2*v.y - v.x)
   line(x.x,x.y,x.x - 2*v.x - v.y,x.y - 2*v.y + v.x)
   if self.showvalue then
      local l,a = z:len(),z:arg()
      if a < 0 then
     arc(o.x,o.y,s*l/3,a,0)
      else
     arc(o.x,o.y,s*l/3,0,a)
      end
      local st = math.floor(
     l * 10^Complex.precision +.5
             )/10^Complex.precision
      self.lfont:write(st,(x.x + o.x)/2,(x.y + o.y)/2)
      st = math.floor(Complex.angle*
     a * 10^Complex.precision/math.pi +.5
             )/10^Complex.precision
    st = st .. Complex.angsym
      x = s*l*vec2(math.cos(a/2),math.sin(a/2))/3 + o
      self.lfont:write(st,x.x,x.y)
   end
end



ComplexPlane.drawLines = {
   None = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      smooth()
      if self.polar then
     self:drawPolar(z)
      else
     self:drawCartesian(z)
      end
      popStyle()
   end,
   Addition = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      smooth()
      for _,u in ipairs{{z,1},{self.controlpt,1},{self.controlpt + z,2}} do
     self:drawCartesian(u[1],u[2])
      end
    if not self.splitscreen then
      stroke(self.veccolour)
      local w = self.controlpt + z
    local s,o = self.scale,self.o
      w = s*w.z + o
      for _,u in ipairs{z,self.controlpt} do
     x = s * u.z + o
     line(w.x,w.y,x.x,x.y)
      end
        end
      popStyle()
   end,
   Multiplication = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      smooth()
    local sh = Complex(self.shifts[#self.shifts])
      for _,u in ipairs{{z,1},{self.controlpt,1},{self.controlpt * z,2}} do
     self:drawPolar(u[1],u[2])
      end
    if not self.splitscreen then
    stroke(self.veccolour)
    local s,o = self.scale,self.o
    local x = o + vec2(s,0)
    line(o.x,o.y,x.x,x.y)
    local y = o + s*z.z
    line(x.x,x.y,y.x,y.y)
    local x = o + s*self.controlpt.z
    local y = o + s*(self.controlpt * z).z
    line(x.x,x.y,y.x,y.y)
        end
      popStyle()
   end,
   Reciprocal = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      smooth()
      if z:is_zero() then
     t = {{z,1}}
      else
     t = {{z,1},{z:reciprocal(),2}}
      end
      for _,u in ipairs (t) do
     if self.polar then
        self:drawPolar(u[1],u[2])
     else
        self:drawCartesian(u[1],u[2])
     end
      end
      popStyle()
   end,
   Minus = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      smooth()
      for _,u in ipairs ({{z,1},{-z,2}}) do
     if self.polar then
        self:drawPolar(u[1],u[2])
     else
        self:drawCartesian(u[1],u[2])
     end
     
      end
      popStyle()
   end,
   Conjugate = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      smooth()
      for _,u in ipairs ({{z,1},{z^"",2}}) do
     if self.polar then
        self:drawPolar(u[1],u[2])
     else
        self:drawCartesian(u[1],u[2])
     end
      end
      popStyle()
   end,
   Exponential = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      smooth()
      for _,u in ipairs({{z,1}, {z^self.controlpt,2}}) do
     self:drawPolar(u[1],u[2])
      end
      self:drawCartesian(self.controlpt)
      popStyle()
   end,
   Roots = function (self,z)
      pushStyle()
      strokeWidth(2)
      noFill()
      lineCapMode(SQUARE)
      stroke(self.veccolour)
      smooth()
      local s = self.scale
      local o = self.o + self.shifts[#self.shifts]
      local v,w,x,y
      local n = 1/self.root
      w = z:power(n,0)
      x = s * w.z + o
      for i = 1,self.root do
     v = z:power(n,i)
     y = s * v.z + o
     line(x.x,x.y,y.x,y.y)
     w,x = v,y
      end
      popStyle()
   end
}

function ComplexPlane:isTouchedBy(touch)
    return RectTouchedBy(self.plane,touch)
end

function ComplexPlane:processTouches(g)
    if self.demo.running then
        self.demo:toggle()
        g:reset()
        return
    end
    if g.updated then
        if g.numactives == 2 and g.type.short then
            g.type.trans = true
        end
        if not g.type.trans then
            local z
            local o = self.o
            local s = self.scale
            local rr = (self.controlr/s)^2
            for k,t in ipairs(g.touchesArr) do
                z = Complex((t.touch.x - o.x)/s,(t.touch.y - o.y)/s)
                if t.touch.state == BEGAN 
                    and not self.ctrltouch
                    and self.controlpt:distSqr(z) < rr
                    then
                        self.ctrltouch = t.id
                end
                if t.id == self.ctrltouch then
                    self.controlpt = self.ctrlcond(z)
                    if t.touch.state == ENDED then
                        self.ctrltouch = nil
                    end
                elseif t.updated then
                    if self.singleton then
                        self.points = {z}
                    else
                        table.insert(self.points,z)
                    end
                end
            end
        elseif g.numactives == 2 then
            local s = self.scale/HEIGHT*4
            local o = self.o
            local ta = g.actives[1]
            local tb = g.actives[2]
            local ea = vec2(ta.touch.x,ta.touch.y)
            local eb = vec2(tb.touch.x,tb.touch.y)
            local sa,sb
            if ta.updated then
                sa = vec2(ta.touch.prevX,ta.touch.prevY)
            else
                sa = ea
            end
            if tb.updated then
                sb = vec2(tb.touch.prevX,tb.touch.prevY)
            else
                sb = eb
            end
            local sc = (sa + sb)/2 - o
            sc = sc / s

            local sl = (sb - sa):len()
            local el = (eb - ea):len()
            self.scale = self.scale * el / sl
            s = s * el/sl
            local ec = (ea + eb)/2 - o
            ec = ec / s
            self.o = self.o + s*(ec - sc)
        end
        g:noted()
    end
    if g.type.ended then
        g:reset()
    end
end

function ComplexPlane:saveStyle(t)
    t = t or {}
    for k,v in ipairs {
            "bgcolour",
            "axescolour",
            "controlcolour",
            "ptcolour",
            "cptcolour",
            "textcolour",
            "scale",
            "showvalue",
            "polar",
            "singleton"
        } do
        t[v] = self[v]
    end
    return t
end

function ComplexPlane:restoreStyle(t)
    t = t or {}
    for k,v in ipairs {
            "bgcolour",
            "axescolour",
            "controlcolour",
            "ptcolour",
            "cptcolour",
            "textcolour",
            "scale",
            "showvalue",
            "polar",
            "singleton"
        } do
        self[v] = t[v] or self[v]
    end
    self.font:setColour(self.textcolour)
end

function ComplexPlane:getPoints(t)
    t = t or {}
    for k,v in ipairs(self.points) do
        table.insert(t,v)
    end
    return t
end

function ComplexPlane:setPoints(t)
    self.points = {}
    for k,v in ipairs(t) do
        table.insert(self.points,v)
    end
end

function ComplexPlane:setDemoText(s)
    s = self:getString(s)
    self.demotext:setLines(unpack(s))
end


function ComplexPlane:defineDemo(ui,opit)
    self.demotext = Textarea({
        font = Font({name = "Courier", size = "20"}),
        pos = function()
                    local x,y = RectAnchorOf(Screen,"east")
                    return x+5,y
                end,
        width = WIDTH - math.min(WIDTH,HEIGHT)-10,
        height = HEIGHT - 10,
        anchor = "east",
        --fit = true,
        title = self:getString("Demo"),
        valign = "top",
        colour = Colour.transparent
        })
    self.demotext:disableTouches()
    ui:addElement(self.demotext)
    local m = ui:addMenu({menuOpts = {
            pos = function()
                local x,y = RectAnchorOf(self.plane,"south east")
                return x+2,y+5
            end,
            anchor = "south west",
            --autoactive = true,
            minWidth = WIDTH - math.min(WIDTH,HEIGHT)-14,
            colour = Colour.svg.DimGrey,
            textColour = Colour.svg.Linen
    }})
    local demoit
    demoit = m:addItem({
        title = self:getString("PauseDemo"),
        action = function()
                if self.demo.paused then
                    self.demo:resume()
                else
                    self.demo:pause()
                end
        end
    })
    m:addItem({
        title = self:getString("SkipDemo"),
        action = function()
            self.demo:skipnext()
        end
    })
    m:addItem({
        title = self:getString("StopDemo"),
        action = function()
            self.demo:stop()
        end
    })
    local savePts
    local saveStyle
    local demoStyle = {}
    local playlist = Playlist({
                 title = self:getString("Demo"),
        lastAction = function()
            self:setHelpText("MainHelp")
            self:clear()
            self:restoreStyle(saveStyle)
            self.demoit.title:setString(self:getString("RunDemo"))
            self.helptext:activate()
            self.demotext:deactivate()
            self.mainmenu.active = true
            m:deactivate()
        end,
        pauseAction = function()
            demoit.title:setString(self:getString("ResumeDemo"))
        end,
        resumeAction = function()
            demoit.title:setString(self:getString("PauseDemo"))
        end

    })

    demoStyle.controlcolour = Colour.svg.SlateBlue
    demoStyle.ptcolour = Colour.svg.Fuchsia
    demoStyle.cptcolour = Colour.svg.Crimson
    demoStyle.scale = HEIGHT/4
    demoStyle.showvalue = true
    demoStyle.polar = false
    demoStyle.singleton = false
    playlist:addEvent({duration = .1, relative = true, event =
        function()
            self:clear()
            saveStyle = self:saveStyle()
            self:restoreStyle(demoStyle)
            self:setDemoText("DemoIntro")
            self.helptext:deactivate()
            self.demotext:activate()
            self.mainmenu.active = false
            m:activate()
            return true
        end
    })
    playlist:pausehere()
    playlist:skippoint()
    playlist:addEvent({duration = .1, relative = true, event =
        function()
            self:setDemoText("DemoAdd")
            return true
        end
    })
    playlist:pausehere()
    playlist:addEvent({duration = 1, relative = true, event = 
        function()
       self.op = ComplexPlane.operations["Addition"]
       self.drawVectors = ComplexPlane.drawLines["Addition"]
       opit.title:setString(self:getString("Addition"))
    self.control = true
            self.controlpt = Complex(-1,0)
            return true
        end
    })
    do
        local y = -1
        local dx = 0
    playlist:addEvent({step = .1, number = 20, relative = true, event = 
        function()
            table.insert(self.points,Complex(1,y))
            y = y + .1
            return true
        end
        })
        playlist:addEvent({step = .1, number = 5, relative = true, event = 
        function()
            y = y - .07
            dx = dx + .07
            table.insert(self.points,Complex(1+dx,y))
            table.insert(self.points,Complex(1-dx,y))
            return true
        end
        })
        playlist:addEvent({duration = .1, relative = true, event = 
        function()
            table.insert(self.points,Complex(1,1))
            return true
        end
        })
    end
    
    playlist:addEvent({number = 20, step = .5, relative = true, event =
        function()
            self.controlpt = self.controlpt
             + Complex(.4*math.random()-.2,.4*math.random()-.2)
            return true
        end
    })
    playlist:pausehere()
    playlist:skippoint()
    playlist:addEvent({duration = .1, relative = true, event =
        function()
            self:clear()
            self:setDemoText("DemoMult")
            return true
        end
    })
    playlist:pausehere()
    playlist:addEvent({duration = 1, relative = true, event = 
        function()
       self.op = ComplexPlane.operations["Multiplication"]
       self.drawVectors = ComplexPlane.drawLines["Multiplication"]
       opit.title:setString(self:getString("Multiplication"))
    self.control = true
            self.controlpt = Complex(1,0)
            self.radius = 5
            self.points = {}
            return true
        end
    })
    do
        local x = -1
        local dy = 0
    playlist:addEvent({step = .1, number = 20, relative = true, event = 
        function()
            table.insert(self.points,Complex(x,1))
            x = x + .1
            return true
        end
        })
        playlist:addEvent({step = .1, number = 5, relative = true, event = 
        function()
            x = x - .07
            dy = dy + .07
            table.insert(self.points,Complex(x,1+dy))
            table.insert(self.points,Complex(x,1-dy))
            return true
        end
        })
        playlist:addEvent({duration = .1, relative = true, event = 
        function()
            table.insert(self.points,Complex(1,1))
            return true
        end
        })
    end
    do
    local n = 0
    playlist:addEvent({number = 21, step = .5, relative = true, event =
        function()
            self.controlpt = 
              Complex.polar(nil,1,n*math.pi/10)
            n = n + 1
            return true
        end
    })
    end
    do
    local x = 1
    local n = 0
    playlist:addEvent({number = 81, step = .2, relative = true, event =
        function()
            self.controlpt = 
              Complex(x,0)
            n = n + 1
            if n < 11 or n > 50 then
                x = x + .1
            else
                x = x - .1
            end
                
            return true
        end
    })
    end
    playlist:pausehere()
    playlist:skippoint()
    playlist:addEvent({duration = .1, relative = true, event =
        function()
            self:clear()
            self:setDemoText("DemoRec")
            return true
        end
    })
    playlist:pausehere()
    playlist:addEvent({duration = .1, relative = true, event =
        function()
       self.op = ComplexPlane.operations["Reciprocal"]
       self.drawVectors = ComplexPlane.drawLines["Reciprocal"]
       opit.title:setString(self:getString("Reciprocal"))
    self.control = false
            self.points = {}
            return true
        end    
    })
    do
        local n = 0
        local x = -1.6
        local y = -1.6
        playlist:addEvent({step = .2, number = 80, relative = true, event =
            function()
                table.insert(self.points,Complex(x,y))
                if n < 20 then
                    x = x + .16
                elseif n < 40 then
                    y = y + .16
                elseif n < 60 then
                    x = x - .16
                else
                    y = y - .16
                end
                n = n + 1
                return true
            end
        })
    end
    playlist:pausehere()
    playlist:skippoint()
    playlist:addEvent({duration = .1, relative = true, event =
        function()
            self:clear()
            self:setDemoText("DemoRoots")
            return true
        end
    })
    playlist:pausehere()
    playlist:addEvent({duration = .1, relative = true, event =
        function()
            self:setDemoText("DemoRootsTurn")
            return true
        end
    })
    playlist:pausehere()
    playlist:addEvent({duration = .1, relative = 0, event = 
        function()
       self.op = ComplexPlane.operations["Roots"]
       self.drawVectors = ComplexPlane.drawLines["Roots"]
       opit.title:setString(self:getString("Roots"))
    self.control = false
            self.points = {}
            self.radius = 10
            return true
        end
    })
    do
        local n = 0
        playlist:addEvent({step = .2, number = 41, relative = true, event =
            function()
                self.points = {Complex.polar(nil,1,n * math.pi/20)}
                n = n + 1
                return true
            end
        })
    end
    playlist:pausehere()
    playlist:addEvent({duration = .1, relative = 0, event = 
        function()
            self.points = {}
            self.root = 5
            return true
        end
    })
    do
        local n = 0
        local x = -1.6
        local y = -1.6
        playlist:addEvent({step = .2, number = 80, relative = true, event =
            function()
                self.points = {Complex(x,y)}
                if n < 20 then
                    x = x + .16
                elseif n < 40 then
                    y = y + .16
                elseif n < 60 then
                    x = x - .16
                else
                    y = y - .16
                end
                n = n + 1
                return true
            end
        })
    end
    playlist:pausehere()
    playlist:addEvent({duration = .1, relative = true, event =
        function ()
            self.points = {Complex(1.5,0)}
            self.root = 2
            return true
        end
    })
    do
        local n = 2
        playlist:addEvent({step = 3, number = 7, relative = true, event =
            function()
                n = n + 1
                self.root = n
                self:setDemoText("DemonthRoot")
                return true
            end
        })
    end
    playlist:pausehere()
    playlist:skippoint()
    playlist:addEvent({duration = .1, relative = true, event =
        function()
            self:setDemoText("DemoEnd")
            return true
        end
    })
    playlist:pausehere()
    self.demo = playlist
end

function ComplexPlane:getString(s)
   if self.Strings[self.language] and self.Strings[self.language][s] then
      if type(self.Strings[self.language][s]) == "function" then
     return self.Strings[self.language][s](self)
      else
     return self.Strings[self.language][s]
      end
   end
   return ""
end

ComplexPlane.Strings = {}
ComplexPlane.Strings.English = {
    Name = "Simply Complex",
    Intro = {
    "Welcome to Simply Complex: the Complex Plane explorer.",
    "This program lets you explore the different operations that are possible with complex numbers. " ..
    "Touch the screen to draw points, then select an operation from the menu to see the effect.",
    "To see a demonstration, select \"Run Demo\" from the main menu.",
    "Tap the screen to begin."
    },
   MainHelp = {
      "Touch the screen to draw points, then select an operation from the menu to see the effect.  " ..
     "For operations that require two numbers (such as addition), the second point is the larger control point.  " ..
    "This can be moved by dragging it around the screen.  " ..
    "Various options are available in the menus: " ..
    "It is possible to constrain the movement of the control point, " ..
    "to draw only one point rather than adding new ones (useful for roots), " ..
    "to move and scale the drawing area (use two fingers on the plane for this), " ..
    "and whether or not to show the values of the points (only those for the last point are shown)."
   },
   AdditionHelp = function() return {
      "The control point is added to each of the inputted points to produce the generated points.",
      "The formula for this is:",
      "z ↦ z₀ + z",
      "In cartesian form:",
      "x + " .. Complex.symbol .. "y ↦ (x₀ + x) + " .. Complex.symbol .. "(y₀ + y)",
      "The formula for polar form isn't so nice.",
      "",
      "The effect is the same as translating all of the points by the vector corresponding to the control point."
   } end,
   MultiplicationHelp = function() return {
      "The control point is multiplied by each of the inputted points to produce the generated points.",
      "The formula for this is:",
      "z ↦ z₀ z",
      "In cartesian form:",
      "x + " .. Complex.symbol .. "y ↦ (x₀ x - y₀ y) + " .. Complex.symbol .. "(x₀ y + y₀ x)",
      "In polar form:",
      "(r,θ) ↦ (r₀ r, θ₀ + θ)",
      "",
      "The effect is the same as scaling all of the points by the length of the vector corresponding to the control point, and rotating them by its argument."
   } end,
   ReciprocalHelp = function() return {
      "The generated points are the reciprocal of the corresponding inputted points.",
      "The formula for this is:",
      "z ↦ 1/z",
      "In cartesian form:",
      "x + " .. Complex.symbol .. "y ↦ x/(x² + y²) - " .. Complex.symbol .. "y/(x² + y²)",
      "In polar form:",
      "(r,θ) ↦ (1/r,- θ)"
   } end,
   ConjugateHelp = function() return {
      "The generated points are the conjugates of the corresponding inputted points.",
      "The formula for this is:",
      "z ↦ z^*",
      "In cartesian form:",
      "x + " .. Complex.symbol .. "y ↦ x - " .. Complex.symbol .. "y",
      "In polar form:",
      "(r,θ) ↦ (r,- θ)"
   } end,
   MinusHelp = function() return {
      "The generated points are minus the corresponding inputted points.",
      "The formula for this is:",
      "z ↦ -z",
      "In cartesian form:",
      "x + " .. Complex.symbol .. "y ↦ - x - " .. Complex.symbol .. "y",
      "In polar form:",
      "(r,θ) ↦ (r,π + θ)",
      "",
      "This should be contrasted with taking conjugates."
   } end,
   ExponentialHelp = {
      "The inputted points are raised to the power given by the control point.",
      "The formula for this is:",
      "z ↦ z^z₀",
      "The formula is easiest to write with the inputted point in polar form and the control point in cartesian form:",
      "(r,θ) ↦ (r^x₀ e^{-θ y₀}, ln(r) y₀ + θ x₀)",
      "",
      "Generically, the exponential function is multivalued.  Here, only one branch is shown."
   },
   RootsHelp = {
      "The roots of the inputted points are shown.",
      "The formula for this in cartesian form is not nice.",
      "In polar form, it is:",
      "(r,θ) ↦ (r^{1/n}, θ/n)",
      "",
      "This is multivalued and all the values are shown.  They form a perfect n-gon around the origin."
   },
   RootsChoose = {
      "This operation will take nth roots.",
      "Use the number spinner to select the root to take, double tap on it to select the number."
   },
   CustomHelp = {
      "You can customise various aspects of the display.",
      "You can change the point size.",
      "You can have it display the square root of minus one as i or j.",
      "You can use degrees or radians for angles.",
    "You can change the precision of the displayed values.",
      "The colour of various elements can be changed via the colour submenu."
   },
    ColourHelp = {"You can change the colours of various parts of the display."},
   ConstrainHelp = {
      "The control point can be constrained to lie in a particular subset of the complex plane.",
      "The options are: no constraint, the real axis, the imaginary axis, the unit circle, and the set of Gaussian integers.",
   },
   OperationHelp = {
      "Here, you can set the operation that is applied to each of your drawn points.",
      "For some, a second point is needed.  This is supplied by the control point.",
      "The available operations are: none, addition, multiplication, reciprocal, conjugation, minus, exponentiating, and taking roots."
   },
    PrecisionHelp = {
    "Drag the number dial to the desired precision, then double tap to select.  The precision is the maximum number of decimal points shown."
    },
    PointSizeHelp = {
    "Drag the slider to adjust the point size and release when the desired size is reached.  The points will adjust dynamically."
    },
   DemoIntro = {
      "This is a demonstration of what the basic operations on complex numbers look like geometrically.",
    "You can pause or stop the demo using the menu at the bottom.",
    "The demo will pause itself to allow you time to read the texts.  When it does so, press \"Continue Demo\" to continue.",
    "Alternatively, while the demo is playing then tapping the main part of the screen will toggle whether it is paused or not."
   },
   DemoAdd = {
      "We start with addition.  The blue control point is added to each of the purple points to produce the corresponding red point.  As the control point moves, so do the results of the addition, in step with the movement of the control point.",
    "(Remember to tap the main screen or press \"Continue Demo\" to continue.)"
   },
   DemoMult = {
      "Now we consider multiplication.  The blue control point is multiplied by each of the purple points to produce the corresponding red point.  Again, as the control point moves, so do the results of the multiplication.  Interesting behaviours occur when the control point moves around the unit circle and when it moves along the real axis."
   },
   DemoRec = {
      "Division is a combination of multiplication and taking reciprocals.  Here, we shall just show the result of taking reciprocals."
   },
   DemoRoots = {
      "Lastly, we show what happens when taking a root of a complex number.  With the exception of 0, every complex number has exactly n nth roots and they are distributed in a perfect n-gon, centred at the origin."
   },
   DemoRootsTurn = {
      "One thing to notice in the following is that as the original point goes around the origin then the roots do not: rather, each moves to the original position of the next root.  It would thus take n turns around the origin to bring each point back to its starting place."
   },
    DemonthRoot = function(self) return {Ordinal(self.root) .. " roots"} end,
   DemoEnd = {
      "That's the end of the demo, thanks for watching.",
    "(Tap the main screen to end the demo.)"
   },
   Roots = "Roots",
   ChooseOperation = "Choose Operation",
   RunDemo = "Run Demo",
   PauseDemo = "Pause Demo",
   SinglePoint = "Single Point",
   TextColour = "Main Labels",
   PolarForm = "Polar Form",
   PrecisionValues = "Precision of Values",
   Customise = "Customise",
   None = "None",
   ResumeDemo = "Continue Demo",
   StopDemo = "Stop Demo",
   SkipDemo = "Skip Step",
   AnglesRadians = "Angles in Radians",
   ConstrainControl = "Constrain Control Point",
   AnglesDegrees = "Angles in Degrees",
   ResetShiftScale = "Reset Shift and Scale",
   UnitCircle = "Unit Circle",
   MainMenu = "Main Menu",
   ImaginaryAxis = "Imaginary Axis",
   ShowValues = "Show Values",
   Exit = "Exit",
   ClearPoints = "Clear Points",
   Demo = "Demo",
   GaussianInteger = "Gaussian Integer",
   RealAxis = "Real Axis",
   PointSize = "Set Point Size",
   ShowVectors = "Show Vectors",
   ControlPointOrigin = "Control Point to Origin",
   Help = "Help",
   Addition = "Addition",
   Multiplication = "Multiplication",
   Reciprocal = "Reciprocal",
   Conjugate = "Conjugate",
   Minus = "Minus",
   Exponential = "Complex Powers",
   BackgroundColour = "Background",
   AxesColour = "Axes",
   ControlPointColour = "Control Point",
   PointColour = "Points",
   ComputedPointColour = "Computed Points",
    LabelColour = "Auxiliary Labels",
    VectorColour = "Auxiliary Lines",
    CustomiseColours = "Customise Colours",
    ResetData = "Reset to initial state",
    Fullscreen = "Full Screen",
    Splitscreen = "Split Screen"
}
