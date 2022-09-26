local lib = {}
Evil = lib

local Pandora = false

function lib.SetPandora(state)
    Pandora = state
end

function lib.PrintVme50()
    local oldPrint = Print
    if Pandora then
        function Print(...)
            local t = {...}
            if os.date('%A') == 'Thursday' then
                if math.random() <= 0.04 then
                    table.insert(t, 'KFC Crazy Thursday V Me 50')
                end
                oldPrint(unpack(t))
            else
                oldPrint(unpack(t))
            end
        end
    end
end

function lib.ShowInfoBox(msg, yes, no, title)
    if Pandora then
        msg = msg or 'KFC Crazy Thursday V Me 50'
        yes = yes or function() end
        no = no or os.exit
        title = title or 'LuaSTGPlus脚本警告'
        local ffi = require 'ffi'
        local ret = ffi.C.MessageBoxA(nil, __UTF8ToANSI(tostring(msg)), __UTF8ToANSI(title), 1 + 48)
        if ret == 1 then
            yes()
        elseif ret == 2 then
            no()
        else
            Print(ret)
        end
    end
end
