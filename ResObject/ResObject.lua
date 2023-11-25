local lib = {}
ResObj = lib

------Lua层资源对象化库by CHX------

-------先偷下chu姥爷的plus.Class-------

local classCreater = function(instance, class, ...)
    local ctor = rawget(class, "init")
    if ctor then
        ctor(instance, ...)  -- 在有构造函数的情况下直接调用
    else
        -- 在没有构造函数的情况下去调用基类的构造函数
        local super = rawget(class, "super")
        if super then
            classCreater(instance, super, ...)
        end
    end
end

---声明一个plus.Class类
---@class pClass plus.Class
---@param base pClass|nil 基类
local function pClass(base)
    local class = { _mbc = {}, super = base }

    local function new(t, ...)
        local instance = {}
        setmetatable(instance, { __index = t })
        classCreater(instance, t, ...)
        return instance
    end

    local function indexer(t, k)
        local member = t._mbc[k]
        if member == nil then
            if base then
                member = base[k]
                t._mbc[k] = member
            end
        end
        return member
    end

    setmetatable(class, {
        __call = new,
        __index = indexer
    })

    return class
end

-------
lib.InfoTable = {}
local typeEnum = {
    Texture = 1,
    Image = 2,
    Animation = 3,
    Music = 4,
    Sound = 5,
    PS = 6,
    Font = 7,
    TTF = 8,
    FX = 9
}

lib.ResObj = pClass()

---资源对象加载
---@param type 'Texture'|'Image'|'Animation'|'Music'|'Sound'|'PS'|'Font'|'TTF'|'FX' 资源类型
---@param name string 资源实名称
---@param pool 'global'|'stage'|'any' 目标资源池 any为当前活跃资源池
---@param async boolean 是否异步加载
---@param ... any 所需的额外的加载信息
function lib.ResObj:Load(type, name, pool, async, ...)
    if pool == 'any' then pool = lstg.GetResourceStatus() end
    if not self.type then
        self.type = assert(typeEnum[type], 'Invalid resource type \'', type, '\'')
    else
        self:ReLoad(type, name, pool, async)
        return
    end

    assert(lstg.CheckRes(self.type, name) ~= pool, string.format('Resource %s with type %s in %s pool is already exist!', name, type, pool))
    self.name = name

    local poolState = lstg.GetResourceStatus()
    lstg.SetResourceStatus(pool)
    _G['Load' .. type](name, ...)
    lstg.SetResourceStatus(poolState)
end