local lib = {}
ObjRes = lib

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

local asyncQueue = {size = 32768, head = 0, tail = 0}
function asyncQueue.push(t)
    asyncQueue[asyncQueue.tail] = t
    asyncQueue.tail = (asyncQueue.tail + 1) % asyncQueue.size
end
function asyncQueue.pop()
    local data = asyncQueue[asyncQueue.head]
    asyncQueue[asyncQueue.head] = nil
    asyncQueue.head = (asyncQueue.head + 1) % asyncQueue.size
    return data
end

local nullName = "null"

lib.ResObj = pClass()
function lib.ResObj:init()
    self.name = nullName
    self.type = 0
    self.derive = {}
end

---派生一个资源对象 修改它不会影响源对象
function lib.ResObj:Derive()
    --TODO
end

---资源对象加载
---@param type 'Texture'|'Image'|'Animation'|'Music'|'Sound'|'PS'|'Font'|'TTF'|'FX' 资源类型
---@param name string 资源实名称
---@param async boolean 是否异步加载 安全起见,异步加载的资源全部会被导出到global池
---@param ... any 所需的额外的加载信息
function lib.ResObj:Load(type, name, async, ...)
    if self.type == 0 then
        self.type = assert(typeEnum[type], 'Invalid resource type \'', type, '\'')
    else
        self:ReLoad(type, name, async)
        lstg.Print("[ObjectResourceLib][Warning] Attempt to Load a loaded resource ", name, ", automatically using ReLoad method.")
        return self
    end

    assert(not lstg.CheckRes(self.type, name), string.format('Resource %s with type %s is already exist!', name, type))
    self.name = name

    if async then
        asyncQueue.push({'Load' .. type, name, ...})
    else
        _G['Load' .. type](name, ...)
    end
    return self
end

---资源对象重加载  
---警告 此行为会切断派生关系 如果有派生对象(比如说 出于性能目的缓存对象)无法通过释放该对象来自动释放
---@param type 'Texture'|'Image'|'Animation'|'Music'|'Sound'|'PS'|'Font'|'TTF'|'FX' 资源类型
---@param name string 资源实名称
---@param async boolean 是否异步加载 安全起见,异步加载的资源全部会被导出到global池
---@param ... any 所需的额外的加载信息
function lib.ResObj:ReLoad(type, name, async, ...)
    self.derive = {}
    if async then
        asyncQueue.push({'lstg.RemoveResource' .. type, 'global', self.type, self.name})
        self.type = assert(typeEnum[type], 'Invalid resource type \'', type, '\'')
        assert(not lstg.CheckRes(self.type, name), string.format('Resource %s with type %s is already exist!', name, type))
        asyncQueue.push({'Load' .. type, name, ...})
    else
        lstg.RemoveResource('global', self.type, self.name)
        self.type = assert(typeEnum[type], 'Invalid resource type \'', type, '\'')
        assert(not lstg.CheckRes(self.type, name), string.format('Resource %s with type %s is already exist!', name, type))
        _G['Load' .. type](name, ...)
    end
    self.name = name
    return self
end



---使用资源对象 该函数直接返回资源名称
function lib.ResObj:Use()
    return self.name
end

---异步对象资源使用
---@param target lstg.GameObject 通常来说在目标obj的init里填self即可
---@param targetVarName any 目标key 比如说修改self.img就填'img'
function lib.ResObj:AsyncUse(target, targetVarName)
    task.New(target, function()
        while self.name == nullName do
            task.Wait()
        end
        target[targetVarName] = self.name
    end)
end

lib.Image = pClass(lib.ResObj)

---设置图片渲染缩放, 默认为1
---@param async any
---@param scale any
function lib.Image:SetScale(async, scale)
    if async then
        asyncQueue.push({'lstg.SetImageScale', self.name, scale})
    else
        lstg.SetImageScale(self.name, scale)
    end
    return self
end

---设置图片状态
---@param blendmode lstg.BlendMode 渲染模式
---@param ... lstg.Color 顶点颜色
function lib.Image:SetState(async, blendmode, ...)
    if async then
        asyncQueue.push({'lstg.SetImageState', self.name, blendmode, ...})
    else
        lstg.SetImageState(self.name, blendmode, ...)
    end
    return self
end

return lib