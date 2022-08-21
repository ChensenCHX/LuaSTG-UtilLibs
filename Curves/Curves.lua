local lib = {}
Curves = lib
-------曲线采样库 by CHX-------

local CurveTable = {}


---一般通过检查参数是否有问题的函数
---防范小天才,从我做起(欸嘿)
local function CheckCurve(name, ctrlinfo, mode)
    if CurveTable[name] then
        Print('[Curve Warn] ', name, ' has been used, old data will be delete!')
    else
        CurveTable[name] = {oriposx = {}, oriposy = {}}
    end
    if ctrlinfo.sZoneLow >= ctrlinfo.sZoneHigh then
        error('Invalid sampling zone!', 2)
    end
    if ctrlinfo.sLength <= 0 or ctrlinfo.sLength <= ctrlinfo.sZoneHigh - ctrlinfo.sZoneLow then
        error('Invalid sampling length, sLength<=0 or sLength<sZone!', 2)
    end
end

---对一个待定曲线(参数方程)进行采样  
---@param name string 该曲线名称
---@param curinfo table 包含曲线信息的表
---@param ctrlinfo table 包含采样参数的表
---curinfo表形如{x = function(t) end, y = function(t) end}, 函数的返回值应当为传入的参数的对应值  
---ctrlinfo表形如{sLength = 采样参数变化步长, sZoneLow = 采样区域下界, sZoneHigh = 采样区域上界}  
---注意,如果采样区域无法被步长整除,多余的部分将被舍弃!  
function lib.SamplingCurve(name, curinfo, ctrlinfo)
    CheckCurve(name, ctrlinfo)
    local sZoneLength = ctrlinfo.sZoneHigh - ctrlinfo.sZoneLow
    sZoneLength = sZoneLength - sZoneLength%ctrlinfo.sLength
    for _ = ctrlinfo.sZoneLow, sZoneLength do
        CurveTable[name].oriposx[_] = curinfo.x(_)
        CurveTable[name].oriposy[_] = curinfo.y(_)
    end
end

---对一个已采样曲线取等距点
---如果采样精度很糟糕,取点也会很糟糕!!!
---只是一般通过简单逼近实现
---@param name string 曲线名称
---@param length number 目标长度
---@return result table 用于储存结果的表  result.x, result.y表分别存储x坐标y坐标(以数组形式排序)
function lib.Interpolation(name, length)
    local result = {}
    result.x = {CurveTable[name].oriposx[1]}
    result.y = {CurveTable[name].oriposy[1]}
    if not CurveTable[name] then
        error('Invalid Curve name, \'' .. name .. '\' Curve doens`t exist!')
    end
    if length <= 0 then
        error('Invalid interpolation length!')
    end
    local dist = 0
    local tmpdist
    for _ = 1, #CurveTable[name].oriposx do
        tmpdist = Dist(result.x[#result.x], result.y[#result.y], CurveTable[name].oriposx[_], CurveTable[name].oriposy[_])
        if abs(dist + tmpdist - length) > abs(dist - length) then
            table.insert(result.x, CurveTable[name].oriposx[_])
            table.insert(result.y, CurveTable[name].oriposy[_])
        end
    end
    return result
end

---返回包含所有已采样曲线的名称的表(以数组形式排序)
---我也不知道有啥用
function lib.GetAllCurve()
    local Curves = {}
    for k, _ in pairs(CurveTable) do
        table.insert(Curves, k)
    end
    return Curves
end

---删除一个已采样曲线的数据
---@param name string 曲线名称
function lib.DeleteCurve(name)
    CurveTable[name] = nil
end