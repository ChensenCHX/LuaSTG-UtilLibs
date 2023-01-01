Print("[CHXuiLib][Info] 开始加载UI库")

-------旧UI兼容区-------
do
    Include "THlib/UI/uiconfig.lua"
    Include "THlib/UI/font.lua"
    Include "THlib/UI/title.lua"
    Include "THlib/UI/sc_pr.lua"
    
    ui = {}
    
    ui.menu = {
        font_size = 0.625,
        line_height = 24,
        char_width = 20,
        num_width = 12.5,
        title_color = { 255, 255, 255 },
        unfocused_color = { 128, 128, 128 },
        --	unfocused_color={255,255,255},
        focused_color1 = { 255, 255, 255 },
        focused_color2 = { 255, 192, 192 },
        blink_speed = 7,
        shake_time = 9,
        shake_speed = 40,
        shake_range = 3,
        sc_pr_line_per_page = 12,
        sc_pr_line_height = 22,
        sc_pr_width = 320,
        sc_pr_margin = 8,
        rep_font_size = 0.6,
        rep_line_height = 20,
    }
    
    function ui.DrawMenu(title, text, pos, x, y, alpha, timer, shake, align)
        align = align or "center"
        local yos
        if title == "" then
            yos = (#text + 1) * ui.menu.line_height * 0.5
        else
            yos = (#text - 1) * ui.menu.line_height * 0.5
            SetFontState("menu", "", Color(alpha * 255, unpack(ui.menu.title_color)))
            RenderText("menu", title, x, y + yos + ui.menu.line_height, ui.menu.font_size, align, "vcenter")
        end
        for i = 1, #text do
            if i == pos then
                local color = {}
                local k = cos(timer * ui.menu.blink_speed) ^ 2
                for j = 1, 3 do
                    color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
                end
    
                local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
    
                SetFontState("menu", "", Color(alpha * 255, unpack(color)))
                RenderText("menu", text[i], x + xos, y - i * ui.menu.line_height + yos, ui.menu.font_size, align, "vcenter")
                --	RenderTTF("menuttf",text[i],x+xos+2,x+xos+2,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,0,0,0),"centerpoint")
                --	RenderTTF("menuttf",text[i],x+xos,x+xos,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,unpack(color)),"centerpoint")
            else
                SetFontState("menu", "", Color(alpha * 255, unpack(ui.menu.unfocused_color)))
                RenderText("menu", text[i], x, y - i * ui.menu.line_height + yos, ui.menu.font_size, align, "vcenter")
                --	RenderTTF("menuttf",text[i],x+2,x+2,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,0,0,0),"centerpoint")
                --	RenderTTF("menuttf",text[i],x,x,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),"centerpoint")
            end
        end
    end
    
    function ui.DrawMenuTTF(ttfname, title, text, pos, x, y, alpha, timer, shake, align)
        align = align or "center"
        local yos
        if title == "" then
            yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
        else
            yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
            RenderTTF(ttfname, title, x, x, y + yos + ui.menu.sc_pr_line_height, y + yos + ui.menu.sc_pr_line_height, Color(alpha * 255, unpack(ui.menu.title_color)), align, "vcenter", "noclip")
        end
        for i = 1, #text do
            if i == pos then
                local color = {}
                local k = cos(timer * ui.menu.blink_speed) ^ 2
                for j = 1, 3 do
                    color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
                end
                local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
                RenderTTF(ttfname, text[i], x + xos, x + xos, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(alpha * 255, unpack(color)), align, "vcenter", "noclip")
            else
                RenderTTF(ttfname, text[i], x, x, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(alpha * 255, unpack(ui.menu.unfocused_color)), align, "vcenter", "noclip")
            end
        end
    end
    
    function ui.DrawMenuTTFBlack(ttfname, title, text, pos, x, y, alpha, timer, shake, align)
        align = align or "center"
        local yos
        if title == "" then
            yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
        else
            yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
            RenderTTF(ttfname, title, x, x, y + yos + ui.menu.sc_pr_line_height, y + yos + ui.menu.sc_pr_line_height, Color(0xFF000000), align, "vcenter", "noclip")
        end
        for i = 1, #text do
            if i == pos then
                local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
                RenderTTF(ttfname, text[i], x + xos, x + xos, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(0xFF000000), align, "vcenter", "noclip")
            else
                RenderTTF(ttfname, text[i], x, x, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(0xFF000000), align, "vcenter", "noclip")
            end
        end
    end
    
    function ui.DrawRepText(ttfname, title, text, pos, x, y, alpha, timer, shake)
        local yos
        if title == "" then
            yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
        else
            yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
            Render(title, x, y + ui.menu.sc_pr_line_height + yos)
            --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height+1,y+yos+ui.menu.sc_pr_line_height-1,Color(0xFF000000),"center","vcenter","noclip")
            --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(255,unpack(ui.menu.title_color)),"center","vcenter","noclip")
        end
        local _text = text
        local xos = { -300, -240, -120, 20, 130, 240 }
        for i = 1, #_text do
            if i == pos then
                local color = {}
                local k = cos(timer * ui.menu.blink_speed) ^ 2
                for j = 1, 3 do
                    color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
                end
                --			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
                SetFontState("replay", "", Color(0xFFFFFF30))
                --			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(color)),align,"vcenter","noclip")
                for m = 1, 6 do
                    RenderText("replay", _text[i][m], x + xos[m], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "left")
                end
            else
                SetFontState("replay", "", Color(0xFF808080))
                --			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),align,"vcenter","noclip")
                for m = 1, 6 do
                    RenderText("replay", _text[i][m], x + xos[m], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "left")
                end
            end
        end
    end
    
    function ui.DrawRepText2(ttfname, title, text, pos, x, y, alpha, timer, shake)
        local yos
        if title == "" then
            yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
        else
            yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
            Render(title, x, y + ui.menu.sc_pr_line_height + yos)
            --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height+1,y+yos+ui.menu.sc_pr_line_height-1,Color(0xFF000000),"center","vcenter","noclip")
            --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(255,unpack(ui.menu.title_color)),"center","vcenter","noclip")
        end
        local _text = text
        local xos = { -80, 120 }
        for i = 1, #_text do
            if i == pos then
                local color = {}
                local k = cos(timer * ui.menu.blink_speed) ^ 2
                for j = 1, 3 do
                    color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
                end
                --			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
                SetFontState("replay", "", Color(0xFFFFFF30))
                --			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(color)),align,"vcenter","noclip")
                RenderText("replay", _text[i][1], x + xos[1], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "center")
                RenderText("replay", _text[i][2], x + xos[2], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "right")
            else
                SetFontState("replay", "", Color(0xFF808080))
                --			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),align,"vcenter","noclip")
                RenderText("replay", _text[i][1], x + xos[1], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "center")
                RenderText("replay", _text[i][2], x + xos[2], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "right")
            end
        end
    end
    
    local function formatnum(num)
        local sign = sign(num)
        num = abs(num)
        local tmp = {}
        local var
        while num >= 1000 do
            var = num - int(num / 1000) * 1000
            table.insert(tmp, 1, string.format("%03d", var))
            num = int(num / 1000)
        end
        table.insert(tmp, 1, tostring(num))
        var = table.concat(tmp, ",")
        if sign < 0 then
            var = string.format("-%s", var)
        end
        return var, #tmp - 1
    end
    function RenderScore(fontname, score, x, y, size, mode)
        if score < 100000000000 then
            RenderText(fontname, formatnum(score), x, y, size, mode)
        else
            RenderText(fontname, string.format("99,999,999,999"), x, y, size, mode)
        end
    end
    
    function ui.DrawMenuBG()
        SetViewMode "ui"
        Render("menu_bg", 320, 240)
        SetFontState("menu", "", Color(0xFFFFFFFF))
        RenderText("menu",
            string.format("%.1ffps", GetFPS()),
            636, 1, 0.25, "right", "bottom")
        SetViewMode "world"
    end
    
    function ui.DrawFrame()
    end
    
    function ui.DrawScore()
        if not IsValid(lstg.ui) then
            lstg.ui = New(CHXuiLib.mainObject)
        end
    end
end
-----------------------

local ui = {}
CHXuiLib = ui

local uiIV = {FrameFuncList = {}, UIRenderFuncList = {}, WorldRenderFuncList = {}}

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

---主Obj,顺便把各个实际执行函数都塞进去(

ui.mainObject = Class(object)
function ui.mainObject:init()
    self.layer = LAYER_TOP
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
    uiIV.FrameFuncList, uiIV.UIRenderFuncList, uiIV.WorldRenderFuncList = {}, {}, {}
    for _, t in ipairs(methodT) do
        ui.AddEvent(unpack(t))
    end
    methodT.Resources()
    SetResourceStatus(pool)
end

function ui.Init(methodT)
    if not lstg.ui then lstg.ui = New(ui.mainObject) end
    if methodT then ui.LoadUIScheme(methodT) end
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