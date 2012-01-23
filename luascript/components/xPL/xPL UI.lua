--[[

stub file to load the ui files from the insteon component dir

--]]


local c = ComponentManager:GetComponentUsingID (13100)

if c then
    c:LoadUIFiles ()
end

return 'xPL.xml'