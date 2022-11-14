local lib = {}
VarMonitor = lib

-------变量监视器 by CHX-------

---元表类型与结构说明
---items字段用于存储信息
---items.target存放目标表
---items.Read存放读事件函数,其中元素的结构为{name:string, func:function}
---items.Write存放写事件函数,其中元素的结构为{name:string, func:function}

-------功能函数们-------

---针对table类型的元表  
---谔谔,一坨魔幻操作
local TableMt = {
    items = {Read = {}, Write = {}},
    __index = function(t, k)
        if getmetatable(t).items.Read[0] then
            getmetatable(t).items.Read[0][2](getmetatable(t).items.target, k)
        end
        for _, v in ipairs(getmetatable(t).items.Read) do
            v[2](getmetatable(t).items.target, k)
        end
        return getmetatable(t).items.target[k]
    end,
    __newindex = function(t, k, value)
        if getmetatable(t).items.Read[0] then
            getmetatable(t).items.Read[0][2](getmetatable(t).items.target, k, value)
        end
        for _, v in ipairs(getmetatable(t).items.Write) do
            v[2](getmetatable(t).items.target, k, value)
        end
    end
}

---抄了个深拷贝函数 from https://blog.mutoo.im/2015/10/deepclone-in-lua/  
---不可处理相同元素问题
local function DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end

        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end

---创建监控空表  
---绑上特制元表以提供各种神秘操作
local function TableCreate(var)
    local mt = getmetatable(var)
    if mt then
        local items = {
            target = var,
            Read = {[0]={'__origin', mt.__index}},
            Write = {[0]={'__origin', mt.__newindex}}
        }
        mt = DeepCopy(mt)
        mt.items, mt.__index, mt.__newindex = items, TableMt.__index, TableMt.__newindex
        setmetatable(var, nil)
        var = setmetatable({}, mt)
    else
        mt = DeepCopy(TableMt)
        mt.items.target = var
        var = setmetatable({}, mt)
    end
    return var
end

-------向外提供的函数们-------

---创建监控 以var = lib.Create(var)形式使用  
---仅支持对table使用
function lib.CreateMonitor(var)
    if type(var) == "table" then return TableCreate(var)
    else error("Illegal type.") end
end

---插入事件函数  
---target为目标监控器, mode为字符串,若为pos表示指定顺序模式,若为none表默认插入到尾部模式   
---info.pos为坐标(负数表从后向前), info.name为事件名称, info.type为事件类型, info.func为事件函数  
---info.type可为"Read", "Write"
function lib.InsertEvent(target, mode, info)
    if mode == "pos" then
        table.insert(getmetatable(target).items[info.type], info.pos, {info.name, info.func})
    elseif mode == "none" then
        table.insert(getmetatable(target).items[info.type], {info.name, info.func})
    else
        error("Illegal mode.")
    end
end

---删除事件函数  
---target为目标监控器, mode为字符串,若为pos表示指定顺序模式,若为name表指定名称模式,若为none表默认删除尾部模式  
---info.pos为坐标(负数表从后向前), info.name为事件名称, info.type为事件类型  
---info.type可为"Read", "Write"
function lib.DeleteEvent(target, mode, info)
    if mode == "pos" then
        table.remove(getmetatable(target).items[info.type], info.pos)
    elseif mode == "name" then
        for _, v in ipairs(getmetatable(target).items[info.type]) do
            if v[1] == info.name then
                table.remove(getmetatable(target).items[info.type], _)
            end
        end
    elseif mode == "none" then
        table.remove(getmetatable(target).items[info.type])
    else
        error("Illegal mode.")
    end
end

---默认的写入表函数  
---建议直接不假思索插到监控Write项第一位
function lib.defaultWrite(t, k, v)
    t[k] = v
    Print("writing",t , "with key", k, "with value", v)
end

---默认的读取表函数  
---只是在读值的时候将表,键,值打印出来
function lib.defaultRead(t, k)
    Print("calling",t , "with key", k, "got", t[k])
end

---直接对一个表创建一个搭载默认监视函数的监视器  
function lib.CreateDefaultMonitor(var)
    var = lib.CreateMonitor(var)
    lib.InsertEvent(var, "none", {name = "default", type = "Read", func = lib.defaultRead})
    lib.InsertEvent(var, "none", {name = "default", type = "Write", func = lib.defaultWrite})
    return var
end

---编写写入控制函数与读取监控函数须知
--[[
    读取监控函数的参数应为t, k      t即为当前的真实表 k为待写入的键值
    写入监控函数的参数应为t, k, v   t即为当前的真实表 k为待写入的键值 v为待写入的值
--]]