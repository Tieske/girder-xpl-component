return function(name, default)
    local key = "HKLM"
    local path = [[Software\xPL\]]
    local reg, err, val
    local result = default

    reg, err = win.CreateRegistry(key, path)
    if (reg ~= nil) then
        val = reg:Read(name)
        if (val ~= nil) then
            result = val
        end
        reg:CloseKey()
    end
    return result
end
