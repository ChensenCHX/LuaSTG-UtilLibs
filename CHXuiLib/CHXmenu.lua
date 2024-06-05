-------用户交互界面库By CHX-------

local lib = {}
CHXmuLib = lib --导出全局包

-------Menu部分-------

local menu = {}

---@class TitleSchemeTable
local t = {
    elemT = {},


    globalResLoader = function() end,
    globalResList = {},
    localResLoader = function () end
}

function lib.ChangeLoadScheme(t)
    local pool = lstg.GetResourceStatus() or "global"
    lstg.SetResourceStatus("global")
    if menu.currentScheme then
        for k, v in pairs(menu.currentScheme.globalResList) do
            lstg.RemoveResource("global", k, v)
        end
    end
    menu.currentScheme = t
    t.globalResLoader()
    lstg.SetResourceStatus(pool)
end

local menuStage = stage.New('menu', false, true)
function menuStage:init()
    self.Stack = lib.MakeStack(false)
    menu.currentScheme.localResLoader()

    self.Stack:push(menu.currentScheme.elemT.main)
end

-------杂项工具-------

---创建一个栈 支持:push(val) :pop() :isEmpty() :top()  
---额外支持从栈顶到栈底的访问 :currVal() :lowVal() :highVal() :setPos(offset)  
---setPos参数若为正则为从顶向底 为负则为从底向顶 为0设置到栈顶 栈顶栈底为1与-1
---@param isCircle boolean 控制访问方法是否为循环的
---@return table Stack
function lib.MakeStack(isCircle)
    return {
        head = 1,
        top = function(self)
            return self[self.head-1]
        end,
        push = function(self, v)
            self[self.head] = v
            self.head = self.head + 1
        end,
        pop = function(self)
            if self:isEmpty() then return nil
            else self.head = self.head - 1 return self[self.head] end
        end,
        isEmpty = function(self)
            return self.head == 1
        end,

        curr = 1,
        currVal = function(self)
            if self:isEmpty() then return nil end
            return self[self.curr]
        end,
        lowVal = function(self)
            if self:isEmpty() then return nil end
            if isCircle then
                if self.curr == 1 then self.curr = self.head - 1
                else self.curr = self.curr - 1 end
            else
                self.curr = math.max(1, self.curr - 1)
            end
            return self[self.curr]
        end,
        highVal = function(self)
            if self:isEmpty() then return nil end
            if isCircle then
                self.curr = self.curr + 1
                if self.curr == self.head then self.curr = 1 end
            else
                self.curr = math.min(self.head-1, self.curr + 1)
            end
            return self[self.curr]
        end,
        setPos = function(self, offset)
            if offset == 0 or self:isEmpty() then self.curr = self.head return end
            if offset < 0 then
                self.curr = (-offset % self.head-1) + 1
            else
                self.curr = self.head - ((offset % self.head-1) + 1)
            end
        end
    }
end

---创建一个队列 支持:push(val) :pop() :isEmpty() :size()  
---额外支持从队头到队尾的访问 模式取决于是否isCircle  
---相应方法 :nextVal() :lastVal() :currVal() :setPos(bool head|tail, offset)
---@param isCircle boolean 控制访问方法是否为循环的
---@return table Stack
function lib.MakeQueue(isCircle)
    return {
        len = 0,
        head = 1, tail = 1,
        curr = 1,
        push = function(self, v)
            self[self.tail] = v
            self.tail = self.tail+1
        end,
        pop = function(self)
            local val = self[self.head]
            self[self.head] = nil
            self.head = self.head+1
            return val
        end,
        isEmpty = function(self)
            return self.head == self.tail
        end,
        size = function(self)
            return self.tail - self.head
        end,
        nextVal = function(self)
            if self:isEmpty() then return nil end
            if isCircle then
                self.curr = self.curr+1
                if self.curr == self.tail then self.curr = self.head end
                return self[self.curr]
            else
                self.curr = math.max(self.curr+1, self.tail)
                return self[self.curr]
            end
        end,
        lastVal = function(self)
            if self:isEmpty() then return nil end
            if isCircle then
                self.curr = self.curr-1
                if self.curr < self.head then self.curr = self.tail-1 end
                return self[self.curr]
            else
                self.curr = math.max(self.curr-1, self.head)
                return self[self.curr]
            end
        end,
        currVal = function(self)
            return self[self.curr]
        end,
        setPos = function(self, side, offset)
            if self:isEmpty() then self.curr = self.head return end
            if side then
                offset = offset % (self.tail-self.head)
                self.curr = self.head + offset
            else
                offset = offset % (self.tail-self.head)
                self.curr = self.tail - offset - 1
            end
        end
    }
end



return lib