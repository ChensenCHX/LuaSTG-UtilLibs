local lib = {}
AROsys = lib
-------异步加载库 By CHX-------
-------v0.01_bugfixed,谨慎使用-------
-------感谢SSW佬的调试支持 呜呜-------
--[[
    食用手册:
    在你想加入异步加载的Load/Set相关函数前调用AROsys.ReloadFuncs()
    准备就绪后,再次调用AROsys.ReloadFuncs()
    (该步骤可省略 但我会报warn 这是坏的)
    在你准备进行异步加载前调用AROsys.SetExpectFrames(frames)
    frames参数为你期望其使用的帧数(正数,0或负数将报错)
    然后调用AROsys.StartLoading()启动加载流程
    库内提供了丰富的log(雾) 遇事不决请看log.txt
    
    最后祝您
    [ARO INFO]:本次异步加载已完成
--]]

local infos = { Fstate = 'load' }
local items = {
    'LoadTexture',
    'LoadImage', 'CopyImage', 'LoadImageFromFile', 'LoadImageGroup', 'LoadImageGroupFromFile',
    'LoadAnimation', 'LoadAniFromFile',
    'LoadFont', 'LoadTTF',
    'LoadPS', 'LoadFX',
    'LoadSound', 'LoadMusic', 'LoadLaserTexture',

    'SetImageState', 'SetImageCenter',
    'SetAnimationCenter', 'SetAnimationState',
    'SetFontState',
    'SetParState',

    'GetTextureSize'
}

for _, v in ipairs(items) do
    infos[v] = {}
    infos[v].varlist = {}
end

---重载各类资源函数 每次调用会更改至另一状态
function lib.ReloadFuncs()
    if infos.Ostate == 'open' then
        Print '[ARO ERROR]:重载流程无法启动,不应在异步加载流程中调用重载函数,已安全退出'
        return
    end
    infos.Lstate = true
    for _, v in ipairs(items) do
        if not infos[v].old then
            infos[v].old = _G[v]
            _G[v] = function(...)
                local args = { ... }
                table.insert(infos[v].varlist, args)
                Print('[ARO INFO]:已缓存\'', args[1], '\'', '至', v)
            end
            infos.Fstate = 'buff'
            Print(string.format('[ARO INFO]:资源函数%s切换成功 当前为缓存到异步加载表状态', v))
        else
            _G[v] = infos[v].old
            infos[v].old = nil
            infos.Fstate = 'load'
            Print(string.format('[ARO INFO]:资源函数%s切换成功 当前为直接加载状态', v))
        end
    end
end

---设置期望加载消耗的帧数
function lib.SetExpectFrames(frames)
    if frames <= 0 then
        error 'Cannot use 0 frame or negative frames to load.'
    end
    frames = math.ceil(frames)
    local total = 0
    for _, k in pairs(items) do
        if infos[k].varlist then
            total = total + #infos[k].varlist
        end
    end
    local avg, tof = total / frames, 1
    while true do
        if avg % 1 >= 0.1 and avg % 1 <= 0.9 then
            tof = tof + 1
            avg = avg * (tof - 1) / tof
        else
            break
        end
    end
    infos.avgspeed, infos.waitFrames = math.ceil(avg), tof
    infos.Estate = true
    Print(string.format('[ARO INFO]:成功设置期望加载帧,将以加载/设置%d个文件后等待%d帧的模式进行加载'
        , infos.avgspeed, infos.waitFrames))
end

---启动加载(一次加载完成后会自动关闭)
---@return boolean 启动加载动作是否成功
function lib.StartLoading()
    if not infos.Lstate then
        Print '[ARO ERROR]:加载流程无法启动,未调用过重载函数'
        return false
    end
    if infos.Estate and infos.Fstate == 'load' then
        infos.Ostate = 'open'
        Print '[ARO INFO]:加载流程已启动,等待挂载对象加载中'
        infos.Lstate = false
        return true
    elseif not infos.Estate and infos.Fstate == 'buff' then
        Print '[ARO WARN]:无法直接启动加载,函数状态未切换且未设置期望加载帧数,将自动切换状态并使用默认值'
        lib.SetExpectFrames(180)
        lib.ReloadFuncs()
        infos.Ostate = 'open'
        Print '[ARO WARN]:加载流程已启动,使用默认期望加载时间180帧并自动切换函数状态,等待挂载对象加载中'
        infos.Lstate = false
        return true
    elseif not infos.Estate then
        Print '[ARO WARN]:无法直接启动加载,未设置期望加载帧数,将使用默认值'
        lib.SetExpectFrames(180)
        infos.Ostate = 'open'
        Print '[ARO WARN]:加载流程已启动,使用默认期望加载时间180帧,等待挂载对象加载中'
        infos.Lstate = false
        return true
    else
        Print '[ARO WARN]:无法直接启动加载,函数状态未切换,将自动切换状态'
        lib.ReloadFuncs()
        infos.Ostate = 'open'
        Print '[ARO WARN]:加载流程已启动,已自动切换函数状态,等待挂载对象加载中'
        infos.Lstate = false
        return true
    end
end

local function LoadResorce(times)
    local tmp, tmp2 = 0, 0
    for _, v in ipairs(items) do
        tmp = #infos[v].varlist
        tmp2 = tmp2 + tmp
        if infos[v].varlist and tmp > 0 then
            if times > tmp then
                times = times - tmp
                for i = 1, tmp do
                    _G[v](unpack(table.remove(infos[v].varlist, 1)))
                    Print '[ARO INFO]:成功执行加载/设置操作,加载信息见上,设置信息缺省'
                end
                return
            else
                for i = 1, times do
                    _G[v](unpack(table.remove(infos[v].varlist, 1)))
                    Print '[ARO INFO]:成功执行加载/设置操作,加载信息见上,设置信息缺省'
                end
                return
            end
        end
    end
    Print '[ARO INFO]:完成一轮加载循环'
    if tmp2 == 0 then
        infos.Ostate = 'close'
        Print '[ARO INFO]:本次异步加载已完成'
    end
end

local Opr = plus.Class()
function Opr:init()
    Print '[ARO INFO]:已启用异步资源管理系统'
    self.iter = 0
end

function Opr:frame()
    self.iter = self.iter + 1
    if infos.Fstate == 'buff' or infos.Ostate == 'close' then
        return
    end
    if self.iter % infos.waitFrames == 0 then
        LoadResorce(infos.avgspeed)
    end
end

lib.Opr = Opr
