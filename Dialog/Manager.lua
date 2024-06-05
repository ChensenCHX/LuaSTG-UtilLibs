--- 对话系统管理器
--- original Author: 璀镜石
--- modified By: Jerry/辰昕

--- 在原有的基础上暴露出DW渲染器以便进行一些更复杂的文字渲染
--- 例如需要不同颜色，字重，描边的文本等
--- 将来可以考虑进一步扩展

--- 在原有基础上追加了叠层式表情控制
--- 详情见character_set表中的注释

--- 配置流程:
--- 根据需求填写character_set表
--- 在 loadCommonResources() 函数中添加通用资源加载代码
--- 在 createTextRenderer() 函数中修改font_file_list表添加字体文件路径
--- 运行一次, 观察 log 中 Font Collection Detail:\n%s 对应的 %s 信息
--- 使用相应信息修改 DirectWrite.CreateTextFormat() 的第一个参数
--- 按需求修改各种 scale (resolution_scale, box_scale)
--- 到这里配置完成, 编写对应的对话文件即可
--- 
--- 注意:
--- 必须加载dialog:box图片素材作为对话框
--- 注意, 默认对话框缩放后大小为 384x108, 边缘都保留
--- 不得占用 dialog:text_canvas 这一RenderTarget
--- 不得占用 dialog:text 图片素材

local DirectWrite = require("DirectWrite")

local character_set = {
    void = {},
    --[[
        编码角色信息，格式如下
        
        name = {
            root = 文件夹路径,
            head = 共同前缀名,
            images = {
                子图文件名1,
                子图文件名2,
                子图文件名3,
                ...
            },
            
            -- 可选项
            nametag = 名牌名称,
            keywordList = {
                名称 = {
                    images = {子图名1, 子图名2, ...},   -- 注意!! 这里的多层渲染严格按照表内顺序进行
                    xoffsets = {子图1的x偏移, 子图2的x偏移, ...},
                    yoffsets = {子图1的y偏移, 子图2的y偏移, ...}
                },
                ...
            }
            

            -- 立绘横纵缩放
            hscale = hs,
            vscale = vs0,
            
            -- ui 坐标系下的偏移量
            xoffset = xoff,
            yoffset = yoff,

            
        }    
    --]]
}

--------------------------------------------------------------------------------

---@param v1 number
---@param v2 number
---@param k number
---@return number
local function lerp(v1, v2, k)
    return v1 * (1.0 - k) + v2 * k
end

---@param v number 当前值
---@param v1 number 最小值
---@param v2 number 最大值
---@param r number 每次更新时移动的数量
---@param b boolean 往 v2 移动
---@return number
---@overload fun(v:number, r:number, b:boolean): number
local function balance(v, v1, v2, r, b)
    if not r then
        -- 3 个参数的情况
        r = v1
        ---@diagnostic disable-next-line: cast-local-type
        b = v2
        v1 = 0.0
        v2 = 1.0
    end
    if b then
        return math.min(v + r, v2)
    else
        return math.max(v - r, v1)
    end
end

---@param name string
---@param path string
---@param mipmap boolean
---@overload fun(name:string, path:string)
local function loadSpriteFromFile(name, path, mipmap)
    lstg.LoadTexture(name, path, mipmap)
    local w, h = lstg.GetTextureSize(name)
    lstg.LoadImage(name, name, 0, 0, w, h)
end

local function loadCommonResources()
    -- 在这里添加需要的资源
    -- for example:
    loadSpriteFromFile("dialog:box", "assets/dialog/dialogBox.png")
end

---处理DirectWrite并返回渲染器
local function createTextRenderer()
    local resolution_scale = 2
    local canvas_width, canvas_height = 384, 108
    local edge_size = 10
    local outline_with = 2

    local font_file_list = {
        "assets/font/LXGWWenKaiScreen.ttf"
    }
    local font_collection = DirectWrite.CreateFontCollection(font_file_list)
    lstg.Print(string.format("Font Collection Detail:\n%s", font_collection:GetDebugInformation()))

    local text_format = DirectWrite.CreateTextFormat(
        "LXGW WenKai Screen", -- font family name (see DirectWrite.FontCollection:GetDebugInformation result)
        font_collection,
        DirectWrite.FontWeight.Regular,
        DirectWrite.FontStyle.Normal,
        DirectWrite.FontStretch.Normal,
        resolution_scale * 16.0, -- font size in DIP (device independent point, or pixel)
        ""
    )

    ---@type DirectWrite.TextLayout
    local text_layout

    lstg.CreateRenderTarget(
        "dialog:text_canvas",
        resolution_scale * canvas_width,
        resolution_scale * canvas_height
    )
    lstg.LoadImage(
        "dialog:text",
        "dialog:text_canvas",
        0, 0,
        resolution_scale * canvas_width,
        resolution_scale * canvas_height
    )

    local renderer = DirectWrite.CreateTextRenderer()
    renderer:SetTextColor(lstg.Color(255, 255, 255, 255))
    renderer:SetTextOutlineColor(lstg.Color(255, 0, 0, 0))
    renderer:SetTextOutlineWidth(resolution_scale * outline_with)
    renderer:SetShadowColor(lstg.Color(255, 0, 0, 0)) -- ignore
    renderer:SetShadowRadius(0) -- ignore
    renderer:SetShadowExtend(0) -- ignore

    local R = {}
    ---@param text string
    function R:setText(text)
        text_layout = DirectWrite.CreateTextLayout(
            text,
            text_format,
            resolution_scale * (canvas_width - 2 * (edge_size + outline_with)), -- layout box width
            resolution_scale * (canvas_height - 2 * (edge_size + outline_with)) -- layout box height
        )
        self.dirty = true
    end
    function R:getScale()
        return 1.0 / resolution_scale
    end
    function R:render()
        if self.dirty then
            self.dirty = false
            lstg.PushRenderTarget("dialog:text_canvas")
            lstg.RenderClear(lstg.Color(0, 0, 0, 0))
            lstg.PopRenderTarget() -- "dialog:text_canvas"
            renderer:Render(
                "dialog:text_canvas",
                text_layout,
                resolution_scale * (edge_size + outline_with),
                resolution_scale * (edge_size + outline_with)
            )
        end
    end
    ---获取DW渲染器 请确保你知道你在做什么
    function R:getRenderer()
        return renderer
    end
    ---重设DW渲染器状态为默认状态
    function R:resetRenderer()
        renderer:SetTextColor(lstg.Color(255, 255, 255, 255))
        renderer:SetTextOutlineColor(lstg.Color(255, 0, 0, 0))
        renderer:SetTextOutlineWidth(resolution_scale * outline_with)
        renderer:SetShadowColor(lstg.Color(255, 0, 0, 0)) -- ignore
        renderer:SetShadowRadius(0) -- ignore
        renderer:SetShadowExtend(0) -- ignore
    end
    function R:clearBuffer()
        lstg.PushRenderTarget("dialog:text_canvas")
        lstg.RenderClear(lstg.Color(0, 0, 0, 0))
        lstg.PopRenderTarget() -- "dialog:text_canvas"
    end
    ---直接向文字画布添加文字 注意格式需要自行使用控制符处理
    ---@param text string 目标文字
    ---@param rendererModifier fun() 对renderer的修改操作
    function R:postText(text, rendererModifier)
        rendererModifier()
        local layout = DirectWrite.CreateTextLayout(
            text,
            text_format,
            resolution_scale * (canvas_width - 2 * (edge_size + outline_with)), -- layout box width
            resolution_scale * (canvas_height - 2 * (edge_size + outline_with)) -- layout box height
        )
        renderer:Render(
                "dialog:text_canvas",
                layout,
                resolution_scale * (edge_size + outline_with),
                resolution_scale * (edge_size + outline_with)
        )
    end

    R:setText("")

    return R
end

local function createNametagRenderer()
    local timer = 0
    local disable = true
    local time = 0
    local time1, time2, time3
    local offset1, offset2 = 64, 64

    local function EOQuad(x)
        x = min(1, max(0, x))
        return 1 - (1 - x) * (1 - x);
    end
    local function EIQuad(x)
        x = min(1, max(0, x))
        return x*x
    end

    local R = {}
    function R:enable(id, t1, t2, t3)
        timer = 0
        time = t1+t2+t3
        time1, time2, time3 = t1, t2, t3
        disable = false
        self.img = "character:" .. character_set[id].nametag
    end
    function R:render()
        if disable then
            return
        end
        local pct
        if timer < time1 then
            pct = EOQuad(timer/time1)
            lstg.SetImageState(self.img, "", lstg.Color(pct*255, 255, 255, 255))
            lstg.Render(self.img, 224-pct*offset1, -80, 0, 0.5)
        elseif timer < time1+time2 then
            lstg.SetImageState(self.img, "", lstg.Color(255, 255, 255, 255))
            lstg.Render(self.img, 224-offset1, -80, 0, 0.5)
        else
            pct = EIQuad((timer-time1-time2)/time3)
            lstg.SetImageState(self.img, "", lstg.Color((1-pct)*255, 255, 255, 255))
            lstg.Render(self.img, 224-offset1-pct*offset2, -80, 0, 0.5)
        end

        timer = timer + 1
        if timer > time then
            disable = true
        end
    end
    return R
end

---@param id string
local function loadCharacterImages(id)
    if id == "void" then
        return -- 不绘制空白角色
    end
    local c = character_set[id]
    assert(c, string.format("character id '%s' not found", id))
    for _, v in ipairs(c.images) do
        loadSpriteFromFile("character:" .. v, "assets/character/" .. c.root .. "/" .. v .. ".png")
    end
    if c.nametag then
        loadSpriteFromFile("character:" .. c.nametag, "assets/character/nametag/" .. c.nametag .. ".png")
    end
end

---@param id string
---@param keyword string
local function findCharacterImage(id, keyword)
    local c = character_set[id]
    assert(c, string.format("character id '%s' not found", id))
    for _, v in ipairs(c.images) do
        if string.sub(v, string.len(c.head) + 1) == keyword then
            return "character:" .. v
        end
    end
    assert(false, string.format("character id '%s': image '%s' not found", id, keyword))
end

local character_debug = false

---@param focus_value number
---@param alpha number
---@return lstg.Color
local function getCharacterColor(focus_value, alpha)
    local channel = lerp(64, 255, focus_value)
    local color = lstg.Color(255 * alpha, channel, channel, channel)
    return color
end

---@param id string
---@param keyword string
---@param side game.dialog.Side
---@param focus_value number
---@param alpha number
local function drawCharacter(id, keyword, side, focus_value, alpha)
    if id == "void" then
        return -- 不绘制空白角色
    end
    local cx, cy = (lstg.world.scrl + lstg.world.scrr) / 2, (lstg.world.scrb + lstg.world.scrt) / 2
    local cc = character_set[id]
    local rx, ry = cx - 192 * 0.75, cy
    if side == "right" then
        rx = cx + 192 * 0.75
    end
    local alpha0_offset = 192 * 0.25
    local alpha_offset = alpha0_offset * math.sin(alpha * math.pi / 2)
    if side ~= "right" then
        rx = rx - alpha0_offset + alpha_offset
    else
        rx = rx + alpha0_offset - alpha_offset
    end

    local ox, oy = cc.xoffset or 0, cc.yoffset or 0
    local scale = lerp(1, 1.02, focus_value)
    local color = getCharacterColor(focus_value, alpha)

    if cc.keywordList then
        local imageList = cc.keywordList[keyword]
        for i, image in ipairs(imageList.images) do
            lstg.SetImageState(image, "", color)
            local oox, ooy = imageList.xoffsets[i] or 0, imageList.yoffsets[i] or 0
            lstg.Render(image, rx + ox + oox, ry + oy + ooy, 0, scale * cc.hscale, scale * cc.vscale)
        end
    else
        local image = findCharacterImage(id, keyword)
        lstg.SetImageState(image, "", color)
        lstg.Render(image, rx + ox, ry + oy, 0, scale * cc.hscale, scale * cc.vscale)
    end

    if character_debug then
        lstg.SetImageState("white", "", lstg.Color(255, 255, 0, 255))
        lstg.Render("white", rx, ry, 0, 1)
    end
end

local function getGlobalAlpha()
    local global_alpha = 1.0
    if ext.pause_menu.PauseBackground then
        global_alpha = 1.0 - ext.pause_menu.PauseBackground.alpha
    end
    return global_alpha
end

---@alias game.dialog.Side '"left"' | '"right"'

---@class game.dialog.SceneManager : lstg.GameObject
local Manager = Class(object)
function Manager:init()
    self.addCharacter = Manager.addCharacter
    self.setCharacterActive = Manager.setCharacterActive
    self.drawCharacterGroup = Manager.drawCharacterGroup
    self.setText = Manager.setText
    self.fadeIn = Manager.fadeIn
    self.fadeOut = Manager.fadeOut
    self.wait = Manager.wait
    self.scope = Manager.scope
    self.showName = Manager.showName
    self.clearBuffer = Manager.clearBuffer
    self.postText = Manager.postText
    self.getRenderer = Manager.getRenderer
    self.resetRenderer = Manager.resetRenderer
    loadCommonResources()
    self.text_renderer = createTextRenderer()
    self.nametag_renderer = createNametagRenderer()
    self.layer = LAYER_TOP + 1
    ---@type game.dialog.SceneManager.Character[]
    self.characters = {}
    self.alpha = 0
    self.skip_mode = false
    self.skip_mode_timer = 0
    self.lock = true
end
function Manager:frame()
    task.Do(self)
    if not self.lock and KeyIsDown("next") then
        self.skip_mode_timer = self.skip_mode_timer + 1
    else
        self.skip_mode_timer = 0
    end
    self.skip_mode = KeyIsDown("skip") or (self.skip_mode_timer >= 60)
    for _, c in ipairs(self.characters) do
        c.focus_value = balance(c.focus_value, 1 / 10, c.focus)
        c.alpha = math.min(c.alpha + 1/ 20, 1)
    end
end
---@private
---@param focus boolean
function Manager:drawCharacterGroup(focus)
    local global_alpha = getGlobalAlpha()
    for _, c in ipairs(self.characters) do
        if c.focus == focus then
            drawCharacter(c.id, c.keyword, c.side, c.focus_value * global_alpha, self.alpha * c.alpha * global_alpha)
        end
    end
end
function Manager:render()
    local global_alpha = getGlobalAlpha()
    if global_alpha < 1 / 255 then
        return
    end
    SetViewMode("ui")
    self:drawCharacterGroup(false)
    self:drawCharacterGroup(true)
    SetViewMode("world")
    local color = lstg.Color(255 * self.alpha * global_alpha, 255, 255, 255)
    -- 渲染对话框
    local box_scale = 384 / 924
    lstg.SetImageState("dialog:box", "", color)
    lstg.Render("dialog:box", 0, lstg.world.b + box_scale * 260 / 2, 0, box_scale)
    -- 渲染对话
    -- 理论上对话区域大小是 384x108，边缘都保留 24*scale=10 的宽度后剩下 364x88
    self.text_renderer:render()
    lstg.SetImageState("dialog:text", "", color)
    lstg.Render("dialog:text", 0, lstg.world.b + box_scale * 260 / 2, 0, self.text_renderer:getScale())
    self.nametag_renderer:render()
end
---@param id string
---@param side game.dialog.Side
function Manager:addCharacter(id, side)
    loadCharacterImages(id)
    ---@class game.dialog.SceneManager.Character
    local C = {}
    C.id = id
    C.side = side
    C.focus = false
    C.focus_value = 0
    C.keyword = "正常"
    C.alpha = 0
    table.insert(self.characters, C)
end
---@param id string
---@param keyword string
---@return game.dialog.SceneManager
---@overload fun(self:game.dialog.SceneManager, id:string)
function Manager:setCharacterActive(id, keyword)
    for _, c in ipairs(self.characters) do
        c.focus = (c.id == id)
        if c.focus and keyword then
            c.keyword = keyword
        end
    end
    return self
end
---@param text string
---@return game.dialog.SceneManager
function Manager:setText(text)
    self.text_renderer:setText(text)
    return self
end
---@param time number
---@param wait boolean
---@overload fun(self:game.dialog.SceneManager)
---@overload fun(self:game.dialog.SceneManager, time:number)
function Manager:fadeIn(time, wait)
    time = time or 10
    -- 激活所有已添加的角色
    for _, c in ipairs(self.characters) do
        c.alpha = 1
    end
    local function f()
        for i = 1, time do
            self.alpha = i / time
            task.Wait(1)
        end
        self.lock = false
    end
    if wait then
        f()
    else
        task.New(self, f)
    end
end
---@param time number
---@param wait boolean
---@overload fun(self:game.dialog.SceneManager)
---@overload fun(self:game.dialog.SceneManager, time:number)
function Manager:fadeOut(time, wait)
    time = time or 10
    local function f()
        for i = 1, time do
            self.alpha = 1.0 - (i / time)
            task.Wait(1)
        end
    end
    self.lock = true
    if wait then
        f()
    else
        task.New(self, f)
    end
end
---@param max_seconds number
---@param force boolean
---@return game.dialog.SceneManager
---@overload fun(self:game.dialog.SceneManager, max_seconds:number)
function Manager:wait(max_seconds, force)
    local max_frame = max_seconds * 60 -- 这里锁定每秒 60 帧，虽然理论上可以改
    while max_frame > 0 do
        if not self.lock then
            if not force and (KeyIsPressed("next") or self.skip_mode) then
                if self.skip_mode then
                    for _, c in ipairs(self.characters) do
                        if c.focus then
                            c.focus_value = 1.0
                        else
                            c.focus_value = 0.0
                        end
                    end
                    task.Wait(1) -- 额外的冷却时间
                end
                PlaySound("plst00")
                break
            end
            max_frame = max_frame - 1
        end
        task.Wait(1)
    end
    task.Wait(1)
    return self
end
function Manager:showName(id, t1, t2, t3, wait)
    self.nametag_renderer:enable(id, t1*60, t2*60, t3*60)
    self:wait(t1+t2+t3, wait)
    return self
end
---危险方法 请确保你知道自己在做什么  
---清空文字渲染RT
function Manager:clearBuffer()
    self.text_renderer:clearBuffer()
    return self
end
---危险方法 请确保你知道自己在做什么  
---直接向文字画布添加文字 注意格式需要自行使用控制符处理
---@param text string 目标文字
---@param rendererModifier fun() 对renderer的修改操作
function Manager:postText(text, rendererModifier)
    self.text_renderer:postText(text, rendererModifier)
    return self
end
---危险方法 请确保你知道自己在做什么  
---获取DW渲染器
function Manager:getRenderer()
    return self.text_renderer:getRenderer()
end
---危险方法 请确保你知道自己在做什么 
---重设DW渲染器状态为默认状态
function Manager:resetRenderer()
    self.text_renderer:resetRenderer()
    return self
end
---@param f fun(self:game.dialog.SceneManager)
function Manager:scope(f)
    local old_state = lstg.player.dialog
    ---@diagnostic disable-next-line: inject-field
    lstg.player.dialog = true
    self:fadeIn(20, true)
    f(self)
    self:fadeOut(20, true)
    lstg.Del(self)
    ---@diagnostic disable-next-line: inject-field
    lstg.player.dialog = old_state
end
---@return game.dialog.SceneManager
function Manager.create()
    ---@diagnostic disable-next-line: param-type-mismatch, return-type-mismatch
    return lstg.New(Manager)
end
lstg.RegisterGameObjectClass(Manager)

return Manager
