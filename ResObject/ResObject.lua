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
---@param base any|pClass|nil 基类
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

-------一些枚举量和常量-------

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

local nullName = "null"
local deriveTag = "__derive"

-------异步处理队列与异步处理对象-------

local asyncQueue = {size = 32768, head = 0, tail = 0}
function asyncQueue.push(t)
    asyncQueue[asyncQueue.tail] = t
    asyncQueue.tail = (asyncQueue.tail + 1) % asyncQueue.size
    if asyncQueue.tail == asyncQueue.head then
        error("AsyncQueue is full. Try using higher process speed or bigger queue.")
    end
end
function asyncQueue.pop()
    local data = asyncQueue[asyncQueue.head]
    asyncQueue[asyncQueue.head] = nil
    asyncQueue.head = (asyncQueue.head + 1) % asyncQueue.size
    return data
end
function asyncQueue.empty()
    return asyncQueue.head == asyncQueue.tail
end

lib.asyncProcessor = pClass()

---创建一个异步处理器对象
---@param speed number 处理速度 每帧处理多少个Load请求
---@param patcher lstg.GameObject 挂载对象 可以直接New(objectName)
---@param terminate boolean 处理队列空后是否终止 ture时会在异步处理队列空后销毁自身和所挂载的对象
---@param wait number terminate为false时若队列为空等待多久再进行加载检测
function lib.asyncProcessor:init(speed, patcher, terminate, wait)
    self.counter = 0
    if terminate then
        task.New(patcher, function()
            while true do
                while self.counter < speed do
                    if asyncQueue.empty() then break end
                    
                    local t = asyncQueue.pop()
                    if t[1]:find("Load") then
                        self.counter = self.counter + 1
                    end
                    _G[t[1]](unpack(t, 2))
                end

                self.counter = 0
                task.Wait()
                if asyncQueue.empty() then break end
            end
            Del(patcher)
        end)
    else
        task.New(patcher, function()
            while true do
                while self.counter < speed do
                    if asyncQueue.empty() then break end

                    local t = asyncQueue.pop()
                    if t[1]:find("Load") then
                        self.counter = self.counter + 1
                    end
                    _G[t[1]](unpack(t, 2))
                end

                self.counter = 0
                task.Wait()
                if asyncQueue.empty() then task.Wait(wait) end
            end
        end)
    end
end

-------基类以及基本功能-------

---@class ResObj
lib.ResObj = pClass()
function lib.ResObj:init()
    self.name = nullName
    self.type = 0
    self.rclass = lib.ResObj
    self.derive = {}
end

---派生一个资源对象 修改它不会影响源对象
---@param async boolean
---@return ResObj _ 派生资源对象
function lib.ResObj:Derive(async)
    return self.rclass(async, self.loadInfo[1], self.loadInfo[2] .. deriveTag, unpack(self.loadInfo, 3))
end

---资源对象加载
---@param async boolean 是否异步加载 安全起见,异步加载的资源全部会被导出到global池
---@param type 'Texture'|'Image'|'Animation'|'Music'|'Sound'|'PS'|'Font'|'TTF'|'FX' 资源类型
---@param name string 资源实名称
---@param ... any 所需的额外的加载信息
function lib.ResObj:Load(async, type, name, ...)
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

    self.loadInfo = {type, name, ...}
    return self
end

---资源对象重加载  
---警告 此行为会切断派生关系 如果有派生对象(比如说 出于性能目的缓存对象)无法通过释放该对象来自动释放
---@param async boolean 是否异步加载 安全起见,异步加载的资源全部会被导出到global池
---@param type 'Texture'|'Image'|'Animation'|'Music'|'Sound'|'PS'|'Font'|'TTF'|'FX' 资源类型
---@param name string 资源实名称
---@param ... any 所需的额外的加载信息
function lib.ResObj:ReLoad(async, type, name, ...)
    self.derive = {}
    if async then
        asyncQueue.push({'RemoveResource', 'global', self.type, self.name})
        self.type = assert(typeEnum[type], 'Invalid resource type \'', type, '\'')
        assert(not lstg.CheckRes(self.type, name), string.format('Resource %s with type %s is already exist!', name, type))
        asyncQueue.push({'Load' .. type, name, ...})
    else
        lstg.RemoveResource(lstg.CheckRes(self.type, self.name), self.type, self.name)
        self.type = assert(typeEnum[type], 'Invalid resource type \'', type, '\'')
        assert(not lstg.CheckRes(self.type, name), string.format('Resource %s with type %s is already exist!', name, type))
        _G['Load' .. type](name, ...)
    end

    self.name = name
    self.loadInfo = {type, name, ...}
    return self
end

---释放掉已经加载的资源
---@param async boolean 是否异步释放 注意异步操作只会操作global池的资源该名称同类型资源
---@param recursion boolean 是否递归释放 若是则其派生类也被释放 否则会解除派生关系
function lib.ResObj:Delete(async, recursion)
    if recursion then
        for _, res in ipairs(self.derive) do
            res:Delete(async)
        end
    else
        self.derive = {}
    end

    if async then
        asyncQueue.push({'RemoveResource' .. type, 'global', self.type, self.name})
    else
        lstg.RemoveResource(lstg.CheckRes(self.type, self.name), self.type, self.name)
    end
    self.name = nullName
    self.type = 0
end

---使用资源对象 该函数直接返回资源名称
function lib.ResObj:Use()
    return self.name
end

---异步对象资源使用
---@param target lstg.GameObject 通常来说在目标obj的init里填self即可
---@param targetVarName any 目标key 比如说修改self.img就填'img'
function lib.ResObj:AsyncUse(target, targetVarName)
    target[targetVarName] = self.name
    task.New(target, function()
        while self.name == nullName do
            task.Wait()
        end
        while not asyncQueue.empty() do
            target[targetVarName] = self.name
            task.Wait()
        end
    end)
end

-------一些便用的包装-------

lib.Texture = pClass(lib.ResObj)

function lib.Texture:Load(async, name, ...)
    
    
end

lib.Image = pClass(lib.ResObj)

---加载图片(从纹理)
---@param async boolean 是否异步加载
---@param name string 图片资源名称
---@param ... any LoadImage函数的其余参数(除name) 
function lib.Image:Load(async, name, ...)
    lib.ResObj.Load(self, async, 'Image', name, ...)
    self.rclass = lib.Image
end
lib.Image.init = lib.Image.Load

---设置图片渲染缩放, 默认为1
---@param async any
---@param scale any
function lib.Image:SetScale(async, scale)
    if async then
        asyncQueue.push({'SetImageScale', self.name, scale})
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
        asyncQueue.push({'SetImageState', self.name, blendmode, ...})
    else
        lstg.SetImageState(self.name, blendmode, ...)
    end
    return self
end

function lib.Image:SetCenter(async, x, y)
    if async then
        asyncQueue.push({'SetImageCenter', self.name, x, y})
    else
        lstg.SetImageState(self.name, x, y)
    end
    return self
end

return lib