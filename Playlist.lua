-- Playlist

Playlist = class()

function Playlist:init(t)
    t = t or {}
    self.startat = t.startTime or 0
    if t.skipTo then
        self.skip = t.skipTo
        self.startat = self.startat - t.skipTo
    end
    self.current = t.startTime or 0
    self.lastaction = t.lastAction
    self.pauseaction = t.pauseAction
    self.resumeaction = t.resumeAction
    self.events = {}
    self.skips = {}
    if t.ui then
    local attach = true
    if t.standalone then
        attach = false
    end
    local mopts = t.menuOpts or {}
    local title = t.title or "Playlist"
    local m = t.ui:addMenu({title = title, attach = attach, menuOpts = mopts})
    m:addItem({title = "Start",
        action = function()
            self:start()
            return true
        end,
        highlight = function()
            return self.running
        end
        })
    m:addItem({title = "Stop",
        action = function()
            self:stop()
            return true
        end
        })
    m:addItem({title = "Pause",
        action = function()
            self:pause()
            return true
        end,
        highlight = function()
            return self.paused
        end
        })
    m:addItem({title = "Resume",
        action = function()
            self:resume()
            return true
        end
        })
    end
end

function Playlist:addEvent(t)
    t = t or {}
    local ti = t.time or 0
    if t.relative then
        ti = ti + self.current
    end
    if t.duration then
        self.current = ti + t.duration
        table.insert(self.events,{ti,t.event})
    elseif t.step and t.number then
        for k = 1,t.number do
            table.insert(self.events,{ti,t.event})
            ti = ti + t.step
        end
        self.current = ti
    end
    
end

function Playlist:wait(t)
    if t then
        self.current = self.current + t
    end
end

function Playlist:skippoint(t)
    t = t or self.current
    table.insert(self.skips,t)
end

function Playlist:skipnext()
    if self.running then
        if self.paused then
            self:resume()
        end
        local t = ElapsedTime - self.startat
        local nt
        for k,e in ipairs(self.skips) do
            if e > t then
                if nt then
                    if e < nt then
                        nt = e
                    end
                else
                    nt = e
                end
            end
        end
        if nt then
            self.startat = ElapsedTime - nt
        end
    end
end

function Playlist:pausehere()
    self:addEvent({
        relative = true,
        duration = .1,
        event = function() self:pause() return true end
    })
    self:addEvent({
        relative = true,
        duration = .1,
        event = function() self:resume() return true end
    })
end

function Playlist:draw()
    if self.active then
        local working = false
        for k,e in ipairs(self.events) do
            if not e[3] then
                working = true
                if self.skip and e[1] < self.skip then
                    e[3] = true
                else
                    if ElapsedTime - self.startat > e[1] and e[2]() then
                        e[3] = true
                    end
                end
            end
        end
        if not working then
            self:stop()
        end
    end
end

function Playlist:start()
    self.active = true
    self.running = true
    self.startat = ElapsedTime
    if self.skip then
        self.startat = self.startat - self.skip
    end
    for k,e in ipairs(self.events) do
         e[3] = false
    end
end

function Playlist:pause()
    if not self.paused then
        self.active = false
        self.paused = true
        self.pausedat = ElapsedTime
        if self.pauseaction then
            self.pauseaction()
        end
    end
end

function Playlist:resume()
    if self.paused then
        self.active = true
        self.paused = false
        if self.pausedat then
            self.startat = self.startat + ElapsedTime - self.pausedat
        end
        if self.resumeaction then
            self.resumeaction()
        end
    end
end

function Playlist:toggle()
    if self.paused then
        self:resume()
    else
        self:pause()
    end
end

function Playlist:stop()
    self.active = false
    self.running = false
    if self.lastaction then
        self.lastaction()
    end
end

