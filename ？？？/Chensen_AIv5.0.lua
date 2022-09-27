local AI = {}
Chensen_AI = AI

-------Chensen_AI v5.0 by CHX-------
--[[
    思来想去,最终还是决定复活它并试着制作一个更好的版本
    技术选型上采用v3时期的map+vector方案,不过这次拆分了负责的部分和配置
    同时,感谢lisha桑提供的新思路与Seiwell的启发,可能将引入更好的人机协作方案
    --v4的理论设计需要使用compute shader,而luastg的各种版本都没有支持的准备,于是弃坑

    地图部分负责非激光的弹幕处理
    向量部分负责激光(甚至可能会有曲光?!)的弹幕处理以及对敌机的处理
    希望这次的智障能够不那么智障(笑)
--]]

-------地图段-------
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
    形如map[x][y], x, y指代以世界坐标(0,0)为block[0][0]左下角的偏移block数
--]]


---重置AI判定热力图
local function FlushMap()
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
---@param v number 视野/更新范围 只处理以玩家为中心,v为半径的圆内的弹幕数据
function AI.SetMapParameter(g, u, d, l, r, v)
    map_settings.granularity = math.ceil(g)
    map_settings.up = math.ceil(u)
    map_settings.down = math.ceil(d)
    map_settings.left = math.ceil(l)
    map_settings.right = math.ceil(r)
    map_settings.vision = math.ceil(v)
end

---设定AI热力图性质参数
---@param r number 扩散半径
---@param div number 扩散乘数
---@param default number 默认外层值
function AI.SetMapProperty(r, div, default)
    map_settings.spreadradius = r
    map_settings.divrate = div
    map_settings.default = default
end

AI.SetMapParameter(2, 200, -200, -180, 180, 64)
AI.SetMapProperty(3, 0.05, 5)

---取椭圆长轴及焦点方向 返回值0,1,2代表前长轴,后长轴,正圆
local function maxE(a, b)
    local state = 0
    if a < b then
        a, b = b, a
        state = 1
    elseif a == b then
        state = 2
    end
    return a, b, state
end

local function spint(num)
    if num >= 0 then
        return math.floor(num)
    else
        return math.celi(num)
    end
end

---处理椭圆判定弹幕
---@param a number a轴
---@param b number b轴
---@param rot number 旋转角度
---@param blockx number x坐标(直接传入,内部进行转换)
---@param blocky number y坐标(直接传入,内部进行转换)
local function DoEllipticMapping(a, b, rot, blockx, blocky)
    local state
    blockx, blocky = math.floor(blockx/map_settings.granularity), math.floor(blocky/map_settings.granularity)
    a, b = a/map_settings.granularity, b/map_settings.granularity
    a, b, state = maxE(a, b)
    local c2 = a^2 - b^2
    local c = math.sqrt(c2)
    local int_a = spint(a)
    if state == 2 then
        local r2 = a^2
        for i = blockx - int_a, blockx + int_a do
            for j = blocky - int_a, blocky + int_a do
                if r2 >= i^2 + j^2 then map[i][j] = inf end 
            end
        end
    else
        if state == 1 then rot = rot + 90 end
        local c_x1, c_y1 = c*cos(rot), c*sin(rot)
        local c_x2, c_y2 = -c_x1, -c_y1
        for i = blockx - int_a, blockx + int_a do
            for j = blocky - int_a, blocky + int_a do
                if Dist(c_x1+blockx, c_y1+blocky, i, j) + Dist(c_x2+blockx, c_y2+blocky, i, j) <= 2*a then map[i][j] = inf end
            end
        end
    end
end

---处理矩形判定弹幕
---@param a number a轴
---@param b number b轴
---@param rot number 旋转角度
---@param blockx number x坐标(直接传入,内部进行转换)
---@param blocky number y坐标(直接传入,内部进行转换)
local function DoRectMapping(a, b, rot, blockx, blocky)
    
end

local function ItrateGroups(groups)
    for k, v in ipairs(groups) do
        for _, obj in ObjList(v) do
            if not(obj.node or obj.hide) and obj.colli and Dist(obj, player) <= map_settings.vision then
                if obj.rect then
                    DoRectMapping(obj.a, obj.b, obj.rot, obj.x, obj.y)
                else
                    DoEllipticMapping(obj.a, obj.b, obj.rot, obj.x, obj.y)
                end
            end
        end
    end
end

local function spread(x, y, t, num)
    num = num + 1
    t[x+1][y+1], t[x-1][y+1] = map_settings.default * map_settings.divrate^num
    t[x+1][y-1], t[x-1][y-1] = map_settings.default * map_settings.divrate^num
    if num < map_settings.spreadradius then
        spread(x+1, y+1, t, num)
        spread(x+1, y-1, t, num)
        spread(x-1, y+1, t, num)
        spread(x-1, y-1, t, num)
    end
end

local function SpreadMap()
    local length = spint(map_settings.vision/map_settings.granularity)
    local x, y = math.floor(player.x/map_settings.granularity), math.floor(player.y/map.granularity)
    for i = x-length, x+length do
        for j = y-length, y+length do
            if map[i][j] >= inf then
                if map[i+1][j+1]<inf and map[i+1][j-1]<inf and map[i-1][j+1]<inf and map[i-1][j-1]<inf then
                    spread(i, j, map, 0)
                end
            end
        end
    end
end

function AI.RefreshMap()
    FlushMap()
    ItrateGroups{GROUP_ENEMY_BULLET, GROUP_ENEMY, GROUP_INDES, GROUP_NONTJT}
    SpreadMap()

end