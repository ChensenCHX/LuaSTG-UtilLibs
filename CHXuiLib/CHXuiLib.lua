Print("[CHXuiLib][Info] 开始加载UI库")

local ui = {}
CHXuiLib = ui

local uiIV = {FrameFuncList = {}, UIRenderFuncList = {}, WorldRenderFuncList = {}}

--Include "THlib/UI/uiconfig.lua"
--Include "THlib/UI/font.lua"
--Include "THlib/UI/title.lua"
--Include "THlib/UI/sc_pr.lua"

---主Obj,顺便把各个实际执行函数都塞进去(

ui.mainObject = Class(object)
function ui.mainObject:init()
    self.layer = LAYER_TOP + 1
    self.group = GROUP_GHOST
end

ui.mainObject.frame = uiIV.DoFrame

function ui.mainObject:render()
    SetViewMode("ui")
    uiIV.DoUIRender(self)
    SetViewMode("world")
    uiIV.DoWorldRender(self)
end

-------

function uiIV.DoFrame(self)
    for _, event in ipairs(uiIV.FrameFuncList) do
        event.func(self)
    end
    task.Do(self)
end

function uiIV.DoUIRender(self)
    for _, event in ipairs(uiIV.UIRenderFuncList) do
        event.func(self)
    end
end

function uiIV.DoWorldRender(self)
    for _, event in ipairs(uiIV.WorldRenderFuncList) do
        event.func(self)
    end
end

-------

---增加UI事件
---@param event "UI"|"World"|"Frame" 事件类型
---@param name string 事件名称
---@param func function 执行函数
function ui.AddEvent(event, name, func)
    if type(func) ~= "function" then error("Invalid UI Event argument! Func must be a function!") end
    if event == "UI" then
        table.insert(uiIV.UIRenderFuncList, {name = name, func = func})
    elseif event == "World" then
        table.insert(uiIV.WorldRenderFuncList, {name = name, func = func})
    elseif event == "Frame" then
        table.insert(uiIV.FrameFuncList, {name = name, func = func})
    else error("Invalid UI Event!") end
end

---删除UI事件  
---尽管这里和上面都可以运用连接字符串后作key来省行数但我懒得写了
---@param event "UI"|"World"|"Frame" 事件类型
---@param mode "Name"|"Number" 删除模式
---@param target string|integer 事件名称|事件数
---@return boolean state 是否成功删除该事件
function ui.RemoveEvent(event, mode, target)
    if event == "UI" then
        if mode == "Name" then
            for _, t in ipairs(uiIV.UIRenderFuncList) do
                if t.name == target then
                    table.remove(uiIV.UIRenderFuncList, _)
                    return true
                end
            end
            Print("[CHXuiLib][Warning] 未能找到名为 \"", target, "\" 的事件,未能删除事件")
            return false
        else
            if uiIV.UIRenderFuncList[target] then
                table.remove(uiIV.UIRenderFuncList, target)
                return true
            else
                Print("[CHXuiLib][Warning] 未能找到编号 \"", target, "\" 的事件,未能删除事件")
                return false
            end
        end
    elseif event == "World" then
        if mode == "Name" then
            for _, t in ipairs(uiIV.WorldRenderFuncList) do
                if t.name == target then
                    table.remove(uiIV.WorldRenderFuncList, _)
                    return true
                end
            end
            Print("[CHXuiLib][Warning] 未能找到名为 \"", target, "\" 的事件,未能删除事件")
            return false
        else
            if uiIV.WorldRenderFuncList[target] then
                table.remove(uiIV.WorldRenderFuncList, target)
                return true
            else
                Print("[CHXuiLib][Warning] 未能找到编号 \"", target, "\" 的事件,未能删除事件")
                return false
            end
        end
    elseif event == "Frame" then
        if mode == "Name" then
            for _, t in ipairs(uiIV.FrameFuncList) do
                if t.name == target then
                    table.remove(uiIV.FrameFuncList, _)
                    return true
                end
            end
            Print("[CHXuiLib][Warning] 未能找到名为 \"", target, "\" 的事件,未能删除事件")
            return false
        else
            if uiIV.FrameFuncList[target] then
                table.remove(uiIV.FrameFuncList, target)
                return true
            else
                Print("[CHXuiLib][Warning] 未能找到编号 \"", target, "\" 的事件,未能删除事件")
                return false
            end
        end
    else error("Invalid UI Event!") end
end

---获取承装内部信息的表
---@return table uiIV
function ui.GetuiIV()
    return uiIV
end

---加载一份UI方案  将会直接覆盖前有的UI方案并卸载相应资源
---@param methodT table 
function ui.LoadUIScheme(methodT)
    local pool = GetResourceStatus() or "global"
    SetResourceStatus("global")
    if uiIV.Resource then
        for k, v in pairs(uiIV.Resource) do
            RemoveResource("global", k, v)
        end
    end
    uiIV = {FrameFuncList = {}, UIRenderFuncList = {}, WorldRenderFuncList = {}}
    for _, t in ipairs(methodT) do
        ui.AddEvent(unpack(t))
    end
    methodT.Resources()
    SetResourceStatus(pool)
end

function ui.Init(methodT)
    lstg.ui = New(ui.mainObject)
    ui.LoadUIScheme(methodT)
end

--[[
    UI方案表的格式应当形为
    {
        {Event, Name, func},
        {Event, Name, func},
        ...,
        {Event, Name, func},

        Resource = {
            name0 = type, name1 = type, ..., name_n = type
        }

        Resources = function()
            LoadTexture(name0, ...)
            LoadImage(name1, ...)
            ...
            LoadPS(name_n, ...)
        end
    }

    同时, 我将给出一份示例的CHXuiConfig.lua文件, 为lstg原装宽ui的UI方案
--]]

Print("[CHXuiLib][Info] 成功加载UI库")