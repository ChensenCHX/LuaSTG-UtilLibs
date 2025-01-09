local lib = {}
PlayerMixin = lib

if not lstg.var.PlayerMixin then lstg.var.PlayerMixin = {} end
local CLEAR_COLOR = lstg.Color(0, 0, 0, 0)

--[[
注意!! 应当将所有
New(_G[lstg.var.player_name])
之类的代码替换为
PlayerMixin.createPlayer()
且应当保证lib.SetMixinSet在创建自机前被正确调用!!
--]]

--- 可Mixin的自机必须实现以下条件
---@class PlayerMixin.player : player
local template_player = {}
--- 只进行基本初始化 如加载资源等
function template_player:init() end
--- 自机相关帧事件 注意处理可能存在的子组件
function template_player:frame() end
--- 自机相关渲染事件 注意处理可能存在的子组件
function template_player:render() end
--- 自机相关射击事件 注意处理可能存在的子组件
function template_player:shoot() end
--- 自机相关符卡事件 注意处理可能存在的子组件
function template_player:spell() end
--- 自机相关C事件 注意处理可能存在的子组件
function template_player:special() end
--- 获取自机名 例如reimu_player:get_name() -> reimu 用于拼接replayname
function template_player:get_name() end
--- 将self.imgs[]修改为自己的imgs[]操作写在这里 影响行走图
function template_player:sync_imgs() end
--- 将self.slist[]修改为自己的slist[]操作写在这里 影响子机位置
function template_player:sync_slist() end
--- 将self.hspeed修改为自己的hspeed操作写在这里
function template_player:sync_hspeed() end
--- 将self.lspeed修改为自己的lspeed操作写在这里
function template_player:sync_lspeed() end
--- 将切为高速时要进行的其他修改写在这里
function template_player:sync_miscH() end
--- 将切为低速时要进行的其他修改写在这里
function template_player:sync_miscL() end



---设置Mixin混合自机
---@param classH string 高速自机类全局类名
---@param classL string 低速自机类全局类名
function lib.SetMixinSet(classH, classL)
    lstg.var.PlayerMixin.curr_pH = classH
    lstg.var.PlayerMixin.curr_pL = classL
    local nameH, nameL = _G[classH]:get_name() ,_G[classL]:get_name()
    if nameH == nameL then
        lstg.var.PlayerMixin.curr_replayname = nameH
    else
        lstg.var.PlayerMixin.curr_replayname = nameH .. '&' .. nameL
    end
end

--- 高低速切换时的切换动画时长 单位为f
local EXCHANGE_ANIMATION_LENGTH = 30
local EXCHANGE_ANIMATION_LENGTH_DIV_2 = EXCHANGE_ANIMATION_LENGTH / 2
--- 自机Mixin类 必须先在(例如自机选择界面)调用lib.SetMixinSet后才可正常工作
local playerMixin = Class(player_class)
function playerMixin:init()
    self.pH = _G[lstg.var.PlayerMixin.curr_pH]
    self.pL = _G[lstg.var.PlayerMixin.curr_pL]

    self.pH.init(self)
    self.pL.init(self)

    self.pH.sync_hspeed(self)
    self.pL.sync_lspeed(self)

    self.pH.sync_imgs(self)
    self.pH.sync_slist(self)
    self.pH.sync_miscH(self)

    self.__lastslow = 0
    self.__exchangetimer = 0

    lstg.CreateRenderTarget("rt:playerMixin::pH")
    lstg.CreateRenderTarget("rt:playerMixin::pL")

    local w, s = lstg.world, screen

    lstg.LoadImage("img:playerMixin::pH", "rt:playerMixin::pH", w.scrl*s.scale, (s.height-w.scrt)*s.scale, (w.scrr-w.scrl)*s.scale, (w.scrt-w.scrb)*s.scale)
    lstg.LoadImage("img:playerMixin::pL", "rt:playerMixin::pL", w.scrl*s.scale, (s.height-w.scrt)*s.scale, (w.scrr-w.scrl)*s.scale, (w.scrt-w.scrb)*s.scale)
    SetImageScale("img:playerMixin::pH", 1/s.scale)
    SetImageScale("img:playerMixin::pL", 1/s.scale)
end
function playerMixin:frame()
    self.__exchangetimer = max(0, self.__exchangetimer - 1)
    if self.slow == 1 then self.pL.frame(self) else self.pH.frame(self) end

    -- 这段是Post-process 因为self.p?.frame(self)执行后 self.slow才更新到正确状态
    if self.__lastslow ~= self.slow then
        self.__exchangetimer = self.__exchangetimer <= EXCHANGE_ANIMATION_LENGTH_DIV_2 and EXCHANGE_ANIMATION_LENGTH or self.__exchangetimer
        self.__lastslow = self.slow
        if self.slow == 1 then
            self.pL.sync_imgs(self)
            self.pL.sync_slist(self)
            self.pL.sync_miscL(self)
        else
            self.pH.sync_imgs(self)
            self.pH.sync_slist(self)
            self.pH.sync_miscH(self)
        end
    end
end
function playerMixin:render()
    Print("Message::Render", self.__exchangetimer, self.__lastslow, self.slow)
    if self.__exchangetimer == 0 then
        if self.slow == 1 then
            self.pL.render(self)
        else
            self.pH.render(self)
        end
    else
        -- 用两个rt平滑混合
        local function easeInOutCirc(x)
            if x < 0.5 then return (1 - math.sqrt(1 - ((2 * x)^2))) / 2
            else return (math.sqrt(1 - ((-2 * x + 2)^2)) + 1) / 2 end
        end
        local mixA = 255 * easeInOutCirc(self.__exchangetimer / EXCHANGE_ANIMATION_LENGTH)
        if self.slow == 1 then
            lstg.PushRenderTarget("rt:playerMixin::pH")
            lstg.RenderClear(CLEAR_COLOR)
                self.pH.sync_imgs(self)
                self.pH.sync_slist(self)
                self._wisys.UpdateImage(self)
                self.pH.render(self)
            lstg.PopRenderTarget()  -- rt:playerMixin::pH
            lstg.PushRenderTarget("rt:playerMixin::pL")
                lstg.RenderClear(CLEAR_COLOR)
                self.pL.sync_imgs(self)
                self.pL.sync_slist(self)
                self._wisys.UpdateImage(self)
                self.pL.render(self)
            lstg.PopRenderTarget()  -- rt:playerMixin::pL
            SetImageState("img:playerMixin::pH", "", Color(mixA, 255, 255, 255))
            SetImageState("img:playerMixin::pL", "", Color(255 - mixA, 255, 255, 255))
        else
            lstg.PushRenderTarget("rt:playerMixin::pL")
                lstg.RenderClear(CLEAR_COLOR)
                self.pL.sync_imgs(self)
                self.pL.sync_slist(self)
                self._wisys.UpdateImage(self)
                self.pL.render(self)
            lstg.PopRenderTarget()  -- rt:playerMixin::pL
            lstg.PushRenderTarget("rt:playerMixin::pH")
            lstg.RenderClear(CLEAR_COLOR)
                self.pH.sync_imgs(self)
                self.pH.sync_slist(self)
                self._wisys.UpdateImage(self)
                self.pH.render(self)
            lstg.PopRenderTarget()  -- rt:playerMixin::pH
            SetImageState("img:playerMixin::pH", "", Color(255 - mixA, 255, 255, 255))
            SetImageState("img:playerMixin::pL", "", Color(mixA, 255, 255, 255))
        end

        Render("img:playerMixin::pH", 0, 0)
        Render("img:playerMixin::pL", 0, 0)
    end
end
function playerMixin:shoot()
    if self.slow == 1 then self.pL.shoot(self) else self.pH.shoot(self) end
end
function playerMixin:spell()
    if self.slow == 1 then self.pL.spell(self) else self.pH.spell(self) end
end
function playerMixin:special()
    if self.slow == 1 then self.pL.special(self) else self.pH.special(self) end
end

local globalPlayerMixin = Class(object)
_G['playerMixin'] = globalPlayerMixin;

function lib.createPlayer()
    if lstg.var.PlayerMixin.curr_pH == lstg.var.PlayerMixin.curr_pL then New(_G[lstg.var.PlayerMixin.curr_pH])
    else New(playerMixin) end
end

--- 获取访问player_list[?][3]时对应的名称
---@return string replayname
local function GetCurrentMixinName()
    return lstg.var.PlayerMixin.curr_replayname
end

---添加自机信息到自机信息表  
---注意到这种元表的写法要求必须在访问前保证lstg.var.PlayerMixin.curr_replayname有值    
---考虑到只会在正常进入关卡&播放Replay时创建自机 没有问题
---@param displayname string 显示在菜单中的名字
---@param classname string 原本为自机全局类名 这里仅起游玩信息标注作用
---@param pos number 插入的位置
---@param _replace boolean 是否取代该位置
function lib.AddMixinPlayerToPlayerList(displayname, classname, pos, _replace)
    local record = setmetatable({ displayname, classname }, {
        __index = function(t, k)
            if k == 3 then return GetCurrentMixinName()
            else return nil end
        end})
    if _replace then
        player_list[pos] = record
    elseif pos then
        table.insert(player_list, pos, record)
    else
        table.insert(player_list, record)
    end
end

lib.AddMixinPlayerToPlayerList("reimu&marisa", "reimu_player&marisa_player")
lib.AddMixinPlayerToPlayerList("marisa&reimu", "marisa_player&reimu_player")
lib.AddMixinPlayerToPlayerList("reimu&reimu", "reimu_player&reimu_player")
lib.AddMixinPlayerToPlayerList("marisa&marisa", "marisa_player&marisa_player")

return lib