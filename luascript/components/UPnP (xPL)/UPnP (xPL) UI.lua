--[[

stub file to load the ui files from the insteon component dir

--]]


local c = ComponentManager:GetComponentUsingID (13200)

if c then
    c:LoadUIFiles ()
end

return 'UPnP (xPL).xml'