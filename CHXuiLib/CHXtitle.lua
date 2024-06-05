-------用户交互界面库By CHX-------

local lib = {}
CHXtiLib = lib --导出全局包

-------Title部分-------

local title = {}

---@class TitleSchemeTable
local t = {
    initExec = function(o) end,
    frameExec = function(o) end,
    renderExec = function(o) end,
    delExec = function(o) end,
    masker_in = object,
    in_param = {},
    masker_out = object,
    out_param = {},
    globalResList = {},
    localResLoader = function() end,
    globalResLoader = function() end
}

---更改启动界面方案
---@param t TitleSchemeTable 启动界面方案表
function lib.ChangeLoadScheme(t)
    local pool = lstg.GetResourceStatus() or "global"
    lstg.SetResourceStatus("global")
    if title.currentScheme then
        for k, v in pairs(title.currentScheme.globalResList) do
            lstg.RemoveResource("global", k, v)
        end
    end
    title.currentScheme = t
    t.globalResLoader()
    lstg.SetResourceStatus(pool)
end

---@class stage.Stage
local initstage = stage.New('init', true, true)
function initstage:init()
    lstg.New(title.currentScheme.masker_in, unpack(title.currentScheme.in_param))
    title.currentScheme.localResLoader()
    title.currentScheme.initExec(self)
end
function initstage:frame()
    title.currentScheme.frameExec(self)
end
function initstage:render()
    title.currentScheme.renderExec(self)
end
function initstage:del()
    task.New(self, function()
        self.__maskout = lstg.New(title.currentScheme.masker_out, unpack(title.currentScheme.out_param))
        while IsValid(self.__maskout) do task.Wait() end
        title.currentScheme.delExec(self)
        stage.Set('menu', 'none')
    end)
end



return lib