
-- Use this function to perform your initial setup
supportedOrientations(LANDSCAPE_ANY)
EXPORTED = false

function setup()
    displayMode(FULLSCREEN_NO_BUTTONS)
    touches = Touches()
    ui = UI(touches)
    local cfont = Font({name = "Didot", size = 24})
    argand = ComplexPlane(cfont,ui,touches)
    orientationChanged = _orientationChanged
end


function draw()
    -- process touches and taps
    touches:draw()
    -- draw elements
    argand:draw()
    ui:draw()
    AtEndOfDraw()
end

function touched(touch)
    touches:addTouch(touch)
end

function _orientationChanged(o)
    ui:orientationChanged(o)
end
