INTERRUPT_ARG_INPUT = {}

local function curryStyle(func, argcnt)
    local co = coroutine
    local cof = co.create(function()
        local args = {}
        while #args < argcnt do
            local argipt = {co.yield()}
            for _, arg in ipairs(argipt) do
                if arg == INTERRUPT_ARG_INPUT then break
                else table.insert(args, arg) end
            end
            if arg == INTERRUPT_ARG_INPUT then break end
        end
        return func(unpack(args))
    end)

    local obj
    obj = setmetatable({}, {__call = function(self, ...)
        if(co.status(cof) == "dead") then
            return "Attempt to call a ended curry-style function.", false
        else
            local state, ret = co.resume(cof, ...)
            if(co.status(cof) == "dead") then
                return ret, true
            else
                if state then return obj, false
                else error("An internal error happend in a curry-style function.") end
            end
        end
    end})

    return obj()
end


function MakeCurryStyle(func, arglen)
    return setmetatable({}, {__call = function(self, ...)
        local obj = curryStyle(func, arglen)
        return obj(...)
    end})
end

