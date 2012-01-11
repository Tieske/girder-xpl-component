local function trim (s)
  return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end





-- xPL parser. returns a table.
return function (msg) 
    local x = string.Split(msg, "\n")
    local xPLMsg = {}
    local Line
    local State=1

    xPLMsg.body = {}
    xPLMsg.type = x[1]

    for i in ipairs(x) do

        Line = trim(x[i])

        -- Reading the Body.
        if ( State == 5) then
            if ( Line=='}' ) then
                State = 0
            else
                local t = string.Split( Line, "=")
                if ( table.getn(t)==2 ) then
                    -- 2 elements found, so key and a value
                    table.insert(xPLMsg.body, { key = t[1], value = t[2] })
                elseif ( table.getn(t)==1 ) then
                    -- 1 element found, so key consider it key only
                    table.insert(xPLMsg.body, { key = t[1], value = "" })
                else
                    -- 3 or more elements found, so value contains '=' character
                    table.insert(xPLMsg.body, { key = t[1], value = string.sub(Line, string.len(t[1]) + 2) })
                end
            end
        end

        -- Waiting for Body
        if ( State == 4 ) then
            if ( Line=='{' ) then
                State = 5
            end
        end

        -- Waiting for Schema
        if ( State == 3 ) then

            --if ( Line ~= '' ) and ( Line~='\n') and ( Line~='\r\n' ) and ( Line~='\n\r' ) then
            if ( Line ~= '' ) and ( string.len(Line)>1) then
                xPLMsg.schema = Line
                State = 4
            end

        end

        -- Header.
        if ( State == 2) then
            if ( Line=='}' ) then
                State = 3
            else
                local t = string.Split( Line, "=")
                if ( table.getn(t)==2 ) then
                    xPLMsg[t[1]] = t[2]
                end
            end
        end

        -- Idle
        if ( State == 1 ) then
            if ( Line=='{' ) then
                State = 2
            end
        end
    end
    if not xPLMsg.type then
        return
    end

    if not xPLMsg.source then
        return
    end

    return xPLMsg
end

