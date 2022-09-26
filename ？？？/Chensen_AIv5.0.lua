local AI = {}
Chensen_AI = AI

local inf = 1e20
local map_settings = {}

local mt_mapI = {
    __index =
    function(t, k)
        if k*map_settings.granularity >= map_settings.down and k*map_settings.granularity <= map_settings.up then
            t[k] = 0
        else
            t[k] = inf
        end
        if t.x*map_settings.granularity >= map_settings.left and t.x*map_settings.granularity <= map_settings.right then
            t[k] = 0
        else
            t[k] = inf
        end
        return 0
    end
}
local mt_mapO = {
    __index = 
    function(t, k)
        t[k] = setmetatable({}, mt_mapI)
        t[k].x = k
        return t[k]
    end
}

local map = setmetatable({}, mt_mapO)
--[[
    map表被设计为利用元表自动赋值需要的部分 其余部分直接摆烂不初始化 能省点 大概(
    形如map[x][y], x, y指代以玩家所在block为[0][0]的偏移block数
--]]


---重置AI判定热力图
function AI.FlushMap()
    map = setmetatable({}, mt_mapO)
end

---获取AI热力图生成参数
function AI.GetMapParameter()
    return map_settings
end

---设定AI热力图生成参数  参数全部向上取整
---@param g number 粒度 单位px 设<=0是傻逼
---@param u number 顶边界限 单位px 自己填世界坐标
---@param d number 底边界限 单位px 自己填世界坐标
---@param l number 左边界限 单位px 自己填世界坐标
---@param r number 右边界限 单位px 自己填世界坐标
function AI.SetMapParameter(g, u, d, l, r)
    map_settings.granularity = math.ceil(g)
    map_settings.up = math.ceil(u)
    map_settings.down = math.ceil(d)
    map_settings.left = math.ceil(l)
    map_settings.right = math.ceil(r)
end