local lib = {}
vector = lib

------平面向量库by CHX------

local meta = {}
lib.meta = meta
meta.isvector2d = true
meta.__isbase = true
meta.x = setmetatable({x=1,y=0},{isvector2d = true})
meta.y = setmetatable({x=0,y=1},{isvector2d = true})

local function IsRealNumber(num)
	  if num == 0 then return true
	  else return num%num end
end

---创建一个二维向量基底
---@param vector1 table x基底
---@param vector2 table y基底
function lib.NewBase(vector1, vector2) 
	  local t =
    {
	  	["x"] = vector1,
		  ["y"] = vector2,
	  	__tostring = meta.__tostring,
	  	__add = meta.__add,
	  	__sub = meta.__sub,
	  	__mul = meta.__mul,
	  	__div = meta.__div,
  		__index = meta
    }
	  return setmetatable(t,t)
end

---对一个二维向量基底进行线性变换
---@param base table 原基底
---@param x table 新的x基底向量
---@param y table 新的y基底向量
function lib.TransBase(base, x, y)
    if not base.__isbase then
	      	error(base .. " is not a base!")
	   end
    base.x = x
   	base.y = y
    return base
end

---对一个二维向量基底进行线性变换
---@param base table 原基底
---@param x number x基底向量伸缩倍率
---@param y number y基底向量伸缩倍率
function lib.TransBase2(base, x, y)
    if not base.__isbase then
        error(base .. " is not a base!")
    end
    base.x.x = base.x.x*x
    base.x.y = base.x.y*x
    base.y.x = base.y.x*y
    base.y.y = base.y.y*y
    return base
end

---对一个二维向量基底进行线性变换
---@param base table 原基底
---@param ang number 旋转角度
function lib.TransBaseRot(base, ang)
    if not base.__isbase then
	      	error(base .. " is not a base!")
	   end
    local l1, ang1 = lib.UnpackVector2d2(base.x)
   	local l2, ang2 = lib.UnpackVector2d2(base.y)
    base.x = lib.NewVector2d2(l1, ang1 + ang)
    base.y = lib.NewVector2d2(l2, ang2 + ang)
    return base
end

---对一个二维向量基底进行线性变换
---@param base table 原基底
---@param length number 变化长度
function lib.TransBaseLength(base, length)
    if not base.__isbase then
        error(base .. " is not a base!")
    end
    local x, y = base.x, base.y
    local l1, ang1 = lib.UnpackVector2d2(x)
    local l2, ang2 = lib.UnpackVector2d2(y)
    l1, l2 = l1 + length, l2 + length
    base.x = lib.NewVector2d2(l1, ang1)
    base.y = lib.NewVector2d2(l2, ang2)
    return base
end

---创建一个二维向量（x，y分量）
---@param x number x方向分量
---@param y number y方向分量
---@param base table 基底
function lib.NewVector2d(x, y, base)
    base = base or lib.meta
    if not (IsRealNumber(x) and IsRealNumber(y)) then
	        error(x .. " or " .. y .. " is not a number.", 2)
    end
    if not base.__isbase then
        error(base .. " is not an base!")
    end
    return setmetatable({["x"]=x,["y"]=y}, base)
end

---创建一个二维向量（长度与角度）
---警告：长度与角度会出现不可避免的浮点误差！！
---@param l number 长度
---@param ang number 偏向角
---@param base table 基底
function lib.NewVector2d2(l, ang, base)
    base = base or lib.meta
    if not (IsRealNumber(l) and IsRealNumber(ang)) then
        error(l .. " or " .. ang .. " is not a number.", 2)
    end
    if l == 0 then error("Illegal length.") end
    if not base.__isbase then
        error(base .. " is not an base!")
    end
    local x = l*cos(ang)
    local y = l*sin(ang)
    return setmetatable({["x"]=x,["y"]=y}, base)
end

---打印一个二维向量（x，y分量）
---@param vector table 向量
function lib.PrintVector2d(vector)
    local t = getmetatable(vector)
    if (not t.isvector2d) then
        error(vector .. " is not a vector.")
    end
    return "{"..vector.x*t.x.x+vector.y*t.y.x.." , "..vector.x*t.x.y+vector.y*t.y.y.."}"
end

---打印一个二维向量（长度与角度）
---@param vector table 向量
function lib.PrintVector2d2(vector)
    local t = getmetatable(vector)
    if (not t.isvector2d) then
        error(vector .. " is not a vector.")
    end
    local x,y = vector.x*t.x.x+vector.y*t.y.x, vector.x*t.x.y+vector.y*t.y.y
    return "{"..sqrt((x^2)+(y^2)).." , "..atan2(y, x).."}"
end

---解包一个二维向量（x，y分量）
---@param vector table 向量
function lib.UnpackVector2d(vector)
    local t = getmetatable(vector)
    if (not t.isvector2d) then
        error(vector .. " is not a vector.")
    end
    return vector.x*t.x.x+vector.y*t.y.x, vector.x*t.x.y+vector.y*t.y.y
end

---解包一个二维向量（长度与角度）
---@param vector table 向量
function lib.UnpackVector2d2(vector)
    local t = getmetatable(vector)
    if (not t.isvector2d) then
        error(vector .. " is not a vector.")
    end
    local x,y = vector.x*t.x.x+vector.y*t.y.x, vector.x*t.x.y+vector.y*t.y.y
    return sqrt((x^2)+(y^2)), atan2(y,x)
end

---将两个二维向量相加
---注意，如果两向量不共基底则转换为meta基底！
---@param vector1 table 向量1
---@param vector2 table 向量2
function lib.AddVector2d(vector1, vector2)
    local t1 = getmetatable(vector1)
    local t2 = getmetatable(vector2)
    if (not t1.isvector2d) or (not t2.isvector2d) then
        error(vector1 .. " or " .. vector2 .. " is not a vector.")
    end
    if getmetatable(vector1) == getmetatable(vector2) then
        return setmetatable({["x"]=vector1.x+vector2.x, ["y"]=vector1.y+vector2.y},getmetatable(vector1))
    else
        local t1,t2 = getmetatable(vector1), getmetatable(vector2)
        return setmetatable(
        {
        ["x"] = (vector1.x*t1.x.x+vector1.y*t1.y.x) + (vector2.x*t2.x.x+vector2.y*t2.y.x),
        ["y"] = (vector1.y*t1.x.y+vector1.y*t1.y.y) + (vector2.y*t2.x.y+vector2.y*t2.y.y)
        }, meta)
    end
end

---将两个二维向量相减
---@param vector1 table 向量1
---@param vector2 table 向量2
function lib.SubVector2d(vector1, vector2)
    local t1 = getmetatable(vector1)
    local t2 = getmetatable(vector2)
    if (not t1.isvector2d) or (not t2.isvector2d) then
        error(vector1 .. " or " .. vector2 .. " is not a vector.")
    end
    if getmetatable(vector1) == getmetatable(vector2) then
        return setmetatable({["x"]=vector1.x-vector2.x, ["y"]=vector1.y-vector2.y},getmetatable(vector1))
    else
        local t1,t2 = getmetatable(vector1), getmetatable(vector2)
        return setmetatable(
        {
	      	["x"] = (vector1.x*t1.x.x+vector1.y*t1.y.x) + (vector2.x*t2.x.x+vector2.y*t2.y.x),
		      ["y"] = (vector1.y*t1.x.y+vector1.y*t1.y.y) + (vector2.y*t2.x.y+vector2.y*t2.y.y)
        }, meta)
    end
end

---求两个二维向量点乘值（可能顺序相关）
---@param vector1 table 向量1
---@param vector2 table 向量2
function lib.MulVector2d(vector1, vector2)
    local t1 = getmetatable(vector1)
    local t2 = getmetatable(vector2)
    if (not t1.isvector2d) or (not t2.isvector2d) then
        error(vector1 .. " or " .. vector2 .. " is not a vector.")
    end
    local x1,x2 = vector1.x*t1.x.x+vector1.y*t1.y.x, vector2.x*t2.x.x+vector2.y*t2.y.x
    local y1,y2 = vector1.y*t1.x.y+vector1.y*t1.y.y, vector2.y*t2.x.y+vector2.y*t2.y.y
    return x1*x2 + y1*y2
end

---求A二维向量在B二维向量上的投影长度
---@param vector1 table 向量1
---@param vector2 table 向量2
function lib.Projection(vector1, vector2)
    local t1,t2 = getmetatable(vector1), getmetatable(vector2)
    if (not t1.isvector2d) or (not t2.isvector2d) then
        error(vector1 .. " or " .. vector2 .. " is not a vector.")
    end
    local l1,ang1 = lib.UnpackVector2d2(vector1)
    local l2,ang2 = lib.UnpackVector2d2(vector2)
    return l1*cos(abs(ang1-ang2))
end

---求一个二维向量的垂向量
---注意，求得的结果始终向向量的右侧
---这个操作不会影响向量的基底
---@param vector1 table 向量
function lib.Vertical(vector)
    local x = vector.y * -1
    local y = vector.x
    if y > 0 then
        return lib.NewVector2d(-1*x, -1*y, getmetatable(vector))
    else
        return lib.NewVector2d(x, y, getmetatable(vector))
    end
end

meta.__tostring = lib.PrintVector2d
--调用tostring()时的方法
meta.__add = lib.AddVector2d
--使用+来直接进行向量加法
meta.__sub = lib.SubVector2d
--使用-来直接进行向量减法
meta.__mul = lib.MulVector2d
--使用*来直接进行向量点乘
meta.__div = lib.Projection
--使用/来直接进行向量投影
meta.TransBase = lib.TransBase
--可以直接使用base:TransBase(x,y)的形式来更改基底自身
meta.TransBase2 = lib.TransBase2
--可以直接使用base:TransBaseRot(rot)的形式来更改基底自身
meta.TransBaseRot = lib.TransBaseRot
--可以直接使用base:TransBaseLength(length)的形式来更改基底自身
meta.TransBaseLength = lib.TransBaseLength