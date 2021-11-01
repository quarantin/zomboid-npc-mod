function table.contains(tbl, e)
    for _, v in pairs(tbl) do
        if v == e then
            return true
        end
    end

    return false
end

function table.copy(tbl)
    local t = {}

    for _, v in pairs(tbl) do
        table.insert(t, v)
    end

    return t
end