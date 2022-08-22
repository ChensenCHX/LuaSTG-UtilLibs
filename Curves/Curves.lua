local lib = {}
Curves = lib
-------曲线采样库 by CHX-------

local CurveTable = {}


---一般通过检查参数是否有问题的函数
---防范小天才,从我做起(欸嘿)
local function CheckCurve(name, curinfo, ctrlinfo)
    if CurveTable[name] then
        Print('[Curve Warn] ', name, ' has been used, old data will be delete!')
    else
        CurveTable[name] = {}
        for k, _ in pairs(curinfo) do
            CurveTable[name][k] = {}
        end
    end
    if ctrlinfo.sZoneLow >= ctrlinfo.sZoneHigh then
        error('Invalid sampling zone!', 2)
    end
    if ctrlinfo.sLength <= 0 or ctrlinfo.sLength >= ctrlinfo.sZoneHigh - ctrlinfo.sZoneLow then
        error('Invalid sampling length, sLength<=0 or sLength>sZone!', 2)
    end
end

---对一个待定曲线(参数方程)进行采样  
---@param name string 该曲线名称
---@param curinfo table 包含曲线信息的表
---@param ctrlinfo table 包含采样参数的表
---curinfo表形如{x = function(t) end, y = function(t) end}, 函数的返回值应当为传入的参数的对应值  
---__sinfo为保留字,请勿使用  
---注意,上述x,y等仅作为示例,实际上参方的输出可以任意多维  
---ctrlinfo表形如{sLength = 采样参数变化步长, sZoneLow = 采样区域下界, sZoneHigh = 采样区域上界}  
---注意,如果采样区域无法被步长整除,多余的部分将被舍弃!  
function lib.SamplingCurve(name, curinfo, ctrlinfo)
    CheckCurve(name, curinfo, ctrlinfo)
    local sZoneLength = ctrlinfo.sZoneHigh - ctrlinfo.sZoneLow
    sZoneLength = sZoneLength - sZoneLength%ctrlinfo.sLength
    for _ = ctrlinfo.sZoneLow, sZoneLength, ctrlinfo.sLength do
        for k, v in pairs(curinfo) do
            table.insert(CurveTable[name][k], curinfo[k](_))
        end
    end
    CurveTable[name].__sinfo = ctrlinfo
    CurveTable[name].__sinfo.sSteps = sZoneLength/ctrlinfo.sLength
    CurveTable[name].__sinfo.sZoneHigh = ctrlinfo.sZoneHigh - sZoneLength%ctrlinfo.sLength
end

---对一个已采样曲线进行插值  
---如果采样精度很糟糕,取点也会很糟糕!!!  
---只是一般通过简单逼近实现  
---由于一些原因(我懒) 各种参数不会被以任何形式检查!!(当前版本)  
---所以给我看好了再传参......!!!  
---小贴士:你传入的函数可以访问到result哦(通过访问传入的result)(仅访问,并不能修改值!!)
---@param name string 曲线名称
---@param Infolist table 插值所需信息,按{var,var,...,var}排序,值均为字符串
---@param Ifunc function 插值函数,参数列表按(var,var,...var,result)排序,顺序应同Infolist顺序,返回值应为目标值或false/nil
---@param Ctrllist table 控制信息,按{vararg(多返回值必选) = {'x', 'y' ...}, stepst(可选) = number, steped(可选) = number}传递
---@param Ctrllist table vararg的内容物将表现为result的键值,且顺序相关
---@return result table 用于储存插值结果的表(以数组形式排序),若Ifunc返回值为false/nil则等待下一返回值
function lib.Interpolation(name, Infolist, Ifunc, Ctrllist)
    local result = {}
    local tmplist = {}
    local length = #Infolist
    local tmp
    if Ctrllist.vararg then
        for _ = 1, #Ctrllist.vararg do
            result[Ctrllist.vararg[_]] = {}
        end
    end
    for _ = Ctrllist.stepst or 1, Ctrllist.steped or CurveTable[name].__sinfo.sSteps do
        for i = 1, length do
            tmplist[i] = CurveTable[name][Infolist[i]][_]
        end
        table.insert(tmplist, result)
        tmp = Ifunc(unpack(tmplist))
        if tmp then
            if type(tmp) == 'table' then
                for i = 1, #Ctrllist.vararg do
                    table.insert(result[Ctrllist.vararg[i]], tmp[i])
                end
            else
                table.insert(result, tmp)
            end
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

---返回name对应曲线的所有采样项名称
---@param name string 曲线名称
---@return table 用于承装名称的表
function lib.GetCurveParaName(name)
    if not CurveTable[name] then
        error'Unknown Curve!'
    end
    local result = {}
    for k, v in pairs(CurveTable[name]) do
        table.insert(result, k)
    end
    return result
end

---返回name对应曲线的采样信息  
---返回表键值sLength为采样参数变化步长, sZoneLow为采样区域下界, sZoneHigh为采样区域上界, sSteps为采样步数
---@param name string 曲线名称
---@return table 用于承装采样信息的表
function lib.GetCurveSamplingInfo(name)
    if not CurveTable[name] then
        error'Unknown Curve!'
    end
    return CurveTable[name].__sinfo
end

---删除一个已采样曲线的数据
---@param name string 曲线名称
function lib.DeleteCurve(name)
    CurveTable[name] = nil
end

---提供一些写好的插值函数:
---等距取点  
---最终插值返回的表形如{x = {x1, x2 ...}, y = {y1, y2 ...}}  
---通过闭包形式保存一些信息,实际使用应如下操作   
---xxx = lib.Equidistant(yyy),向插值函数传递xxx  
---注意!!!上述操作创建的迭代函数用完后不会自动释放,需手动赋nil!!!
function lib.Equidistant(length)
    local tmp = {dist = 0}
    return function(x, y, result)
        if #result == 0 then
            tmp.x, tmp.y = x, y
            return {x, y}
        end
        local dist = Dist(tmp.x, tmp.y, x, y)
        if abs(tmp.dist - length) > abs(tmp.dist + dist - length) then
            tmp.x, tmp.y = x, y
            tmp.dist = tmp.dist + dist
            return false
        else
            tmp.x, tmp.y = x, y
            tmp.dist = 0
            return {x, y}
        end
    end
end

---如果你要写自己的插值函数,多返回值请用table传递,且table中值顺序将影响赋给result对应键值的顺序