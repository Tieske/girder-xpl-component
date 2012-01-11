return function (ips)
    local t = string.Split(ips, ",")
    for k,v in ipairs(t) do
        local i = string.Split(v, ".")
        for k1,v1 in ipairs(i) do
            i[k1] = v1 * 1
        end
        t[k] = table.concat(i, ".")
    end
    return table.concat(t, ",")
end
