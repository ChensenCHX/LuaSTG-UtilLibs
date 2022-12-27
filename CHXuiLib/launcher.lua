---------------------------------------
---启动器
---------------------------------------

Include 'THlib\\THlib.lua'

local GetLastKey = lstg.GetLastKey--_GetLastKey

local _key_code_to_name = KeyCodeToName()--Linput
local setting_item = { 'resx', 'resy', 'windowed', 'vsync', 'sevolume', 'bgmvolume', 'res' }
local Resolution = { { 640, 480 }, { 800, 600 }, { 960, 720 }, { 1024, 768 }, { 1280, 960 } }

local settingfile = "Library\\setting"

local function format_json(str)
    local ret = ''
    local indent = '	'
    local level = 0
    local in_string = false
    for i = 1, #str do
        local s = string.sub(str, i, i)
        if s == '{' and (not in_string) then
            level = level + 1
            ret = ret .. '{\n' .. string.rep(indent, level)
        elseif s == '}' and (not in_string) then
            level = level - 1
            ret = string.format(
                    '%s\n%s}', ret, string.rep(indent, level))
        elseif s == '"' then
            in_string = not in_string
            ret = ret .. '"'
        elseif s == ':' and (not in_string) then
            ret = ret .. ': '
        elseif s == ',' and (not in_string) then
            ret = ret .. ',\n'
            ret = ret .. string.rep(indent, level)
        elseif s == '[' and (not in_string) then
            level = level + 1
            ret = ret .. '[\n' .. string.rep(indent, level)
        elseif s == ']' and (not in_string) then
            level = level - 1
            ret = string.format(
                    '%s\n%s]', ret, string.rep(indent, level))
        else
            ret = ret .. s
        end
    end
    return ret
end

function save_setting()
    local f, msg
    f, msg = io.open(settingfile, 'w')
    if f == nil then
        error(msg)
    else
        --f:write(Serialize(cur_setting))--旧方法，但是比较稳定
        f:write(format_json(Serialize(cur_setting)))--新方法by Xrysnow
        f:close()
    end
end

function setting_keys_default()
    cur_setting.keys.up = default_setting.keys.up
    cur_setting.keys.down = default_setting.keys.down
    cur_setting.keys.left = default_setting.keys.left
    cur_setting.keys.right = default_setting.keys.right
    cur_setting.keys.slow = default_setting.keys.slow
    cur_setting.keys.shoot = default_setting.keys.shoot
    cur_setting.keys.special = default_setting.keys.special
    cur_setting.keys.spell = default_setting.keys.spell
    cur_setting.keys2.up = default_setting.keys2.up
    cur_setting.keys2.down = default_setting.keys2.down
    cur_setting.keys2.left = default_setting.keys2.left
    cur_setting.keys2.right = default_setting.keys2.right
    cur_setting.keys2.slow = default_setting.keys2.slow
    cur_setting.keys2.shoot = default_setting.keys2.shoot
    cur_setting.keys2.special = default_setting.keys2.special
    cur_setting.keys2.spell = default_setting.keys2.spell
    cur_setting.keysys.repfast = default_setting.keysys.repfast
    cur_setting.keysys.repslow = default_setting.keysys.repslow
    cur_setting.keysys.menu = default_setting.keysys.menu
    cur_setting.keysys.snapshot = default_setting.keysys.snapshot
    cur_setting.keysys.retry = default_setting.keysys.retry
end

---------------------------------------

stage_launcher = stage.New('settings', true, true)

function stage_launcher:init()
    CHXuiLib.LoadUIScheme(CHXuiLib.Scheme.launcher)
    CHXuiLib.Init()
    LoadTTF('menuttfs', 'THlib\\UI\\font\\default_ttf', 40)
    --
    local f, msg
    f, msg = io.open(settingfile, 'r')
    if f == nil then
        cur_setting = DeSerialize(Serialize(default_setting))
    else
        cur_setting = DeSerialize(f:read('*a'))
        f:close()
    end
    --
    local function ExitGame()
        task.New(self, function()
            task.Wait(30)
            stage.QuitGame()
        end)
    end
    --
    New(mask_fader, 'open')
    --
    menu_title = New(simple_menu, '', {
        { 'Start Game', function()
            menu.FlyIn(menu_mod, 'right')
            menu.FlyOut(menu_title, 'left')
        end },
        { 'Set User Name', function()
            menu.FlyIn(menu_name, 'right')
            menu.FlyOut(menu_title, 'left')
        end },
        { 'Key Settings 1P', function()
            menu.FlyIn(menu_key, 'right')
            menu.FlyOut(menu_title, 'left')
            menu_key.pos = 1
            menu_key.title = 'Key Settings 1P'
            menu_key.key = cur_setting.keys
        end },
        { 'Key Settings 2P', function()
            menu.FlyIn(menu_key, 'right')
            menu.FlyOut(menu_title, 'left')
            menu_key.pos = 1
            menu_key.title = 'Key Settings 2P'
            menu_key.key = cur_setting.keys2
        end },
        { 'Other Settings', function()
            menu.FlyIn(menu_other, 'right')
            menu.FlyOut(menu_title, 'left')
            menu_other.pos = 1
        end },
        { 'Plugin Manager', function()
            menu.FlyIn(menu_plugin, 'right')
            menu.FlyOut(menu_title, 'left')
            _plugin_manager_menu.refresh(menu_plugin)
            --menu_plugin.pos=1
        end },
        { 'Exit Launcher', ExitGame },
        { 'exit', function()
            if menu_title.pos == 7 then
                ExitGame()
            else
                menu_title.pos = 7
            end
        end },
    })
    --
    menu_name = New(name_set_menu)
    --
    local menu_items = {}
    table.insert(menu_items, { 'exit', function()
        menu.FlyIn(menu_title, 'left')
        menu.FlyOut(menu_mod, 'right')
    end })
    menu_mod = New(simple_menu_mod, 'Select Game', menu_items)
    --
    menu_key = New(key_setting_menu, 'Key Settings', {
        { 'Up', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Down', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Left', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Right', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Slow', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Shoot', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Spell', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Special', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'RepFast', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'RepSlow', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Menu', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'SnapShot', function()
            menu_key.edit = true
            menu_key.setting_backup = cur_setting[setting_item[menu_key.pos]]
        end },
        { 'Default', function()
            setting_keys_default()
        end },
        { 'Return To Title', function()
            menu.FlyIn(menu_title, 'left')
            menu.FlyOut(menu_key, 'right')
            save_setting()
        end },
        { 'exit', function()
            if menu_key.pos ~= 14 then
                menu_key.pos = 14
            else
                menu.FlyIn(menu_title, 'left')
                menu.FlyOut(menu_key, 'right')
                save_setting()
            end
        end },
    })
    menu_key.key = cur_setting.keys
    --
    menu_other = New(other_setting_menu, 'Other Settings', {
        { 'Resolution X', function()
            menu_other.edit = true
            menu_other.setting_backup = cur_setting.res
        end },
        { 'Resolution Y', function()
            menu_other.edit = true
            menu_other.setting_backup = cur_setting.res
        end },
        { 'Windowed', function()
            cur_setting.windowed = not cur_setting.windowed
        end },
        { 'Vsync', function()
            cur_setting.vsync = not cur_setting.vsync
        end },
        { 'Sound Volume', function()
        end },
        { 'Music Volume', function()
        end },
        { 'Return To Title', function()
            menu.FlyIn(menu_title, 'left')
            menu.FlyOut(menu_other, 'right')
            save_setting()
        end },
        { 'exit', function()
            if menu_other.pos ~= 7 then
                menu_other.pos = 7
            else
                menu.FlyIn(menu_title, 'left')
                menu.FlyOut(menu_other, 'right')
                save_setting()
            end
        end },
    })
    --
    menu_plugin = New(_plugin_manager_menu, function(self)
        if self.edit then
            self.edit = false
        else
            _plugin_manager_menu.save(self)
            menu.FlyIn(menu_title, 'left')
            menu.FlyOut(menu_plugin, 'right')
        end
    end)
    --
    menu.FlyIn(menu_title, 'right')
end



---------------------------------------

name_set_menu = Class(object)

function name_set_menu:init()
    self.layer = LAYER_TOP
    self.group = GROUP_GHOST
    self.alpha = 1
    self.x = screen.width * 0.5 - 448
    self.y = screen.height * 0.5
    self.bound = false
    self.posx = 5
    self.posy = 5
    self.pos_changed = 0
    self.text = ''
    self.forbidden = {}
    self.title = 'Input User Name'
    self.locked = true
    self.text = cur_setting.username
end

function name_set_menu:frame()
    task.Do(self)
    if self.locked then
        return
    end
    if self.pos_changed > 0 then
        self.pos_changed = self.pos_changed - 1
    end
    if GetLastKey() == setting.keys.up then
        self.posy = self.posy - 1
        self.pos_changed = ui.menu.shake_time
        PlaySound('select00', 0.3)
    end
    if GetLastKey() == setting.keys.down then
        self.posy = self.posy + 1
        self.pos_changed = ui.menu.shake_time
        PlaySound('select00', 0.3)
    end
    if GetLastKey() == setting.keys.left then
        self.posx = self.posx - 1
        self.pos_changed = ui.menu.shake_time
        PlaySound('select00', 0.3)
    end
    if GetLastKey() == setting.keys.right then
        self.posx = self.posx + 1
        self.pos_changed = ui.menu.shake_time
        PlaySound('select00', 0.3)
    end
    self.posx = (self.posx + 12) % 12
    self.posy = (self.posy + 8) % 8
    if KeyIsPressed 'shoot' then
        if self.posx == 11 and self.posy == 7 then
            if self.text == '' then
                self.text = 'User'
            end
            PlaySound('ok00', 0.3)
            cur_setting.username = self.text
            menu.FlyIn(menu_title, 'left')
            menu.FlyOut(menu_name, 'right')
            save_setting()
            return
        end
        if #self.text == 16 then
            self.posx = 11
            self.posy = 7
        else
            local char = string.char(0x20 + self.posy * 12 + self.posx)
            self.text = self.text .. char
            PlaySound('ok00', 0.3)
        end
    elseif KeyIsPressed 'spell' then
        PlaySound('cancel00', 0.3)
        if #self.text == 0 then
            self.text = 'User'
            self.posx = 11
            self.posy = 7
        else
            self.text = string.sub(self.text, 1, -2)
        end
    end
end

function name_set_menu:render()
    SetFontState('menu', '', Color(self.alpha * 255, unpack(ui.menu.unfocused_color)))
    for posx = 0, 11 do
        for posy = 0, 7 do
            if posx ~= self.posx or posy ~= self.posy then
                RenderText('menu', string.char(0x20 + posy * 12 + posx), self.x + (posx - 5.5) * ui.menu.char_width, self.y - (posy - 3.5) * ui.menu.line_height, ui.menu.font_size, 'centerpoint')
            end
        end
    end
    local color = {}
    local k = cos(self.timer * ui.menu.blink_speed) ^ 2
    for j = 1, 3 do
        color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
    end
    SetFontState('menu', '', Color(self.alpha * 255, unpack(color)))
    RenderText('menu', string.char(0x20 + self.posy * 12 + self.posx),
            self.x + (self.posx - 5.5) * ui.menu.char_width + ui.menu.shake_range * sin(ui.menu.shake_speed * self.pos_changed),
            self.y - (self.posy - 3.5) * ui.menu.line_height,
            ui.menu.font_size, 'centerpoint')
    SetFontState('menu', '', Color(self.alpha * 255, unpack(ui.menu.title_color)))
    RenderText('menu', self.title, self.x, self.y + 5.5 * ui.menu.line_height, ui.menu.font_size, 'centerpoint')
    RenderText('menu', self.text, self.x, self.y - 5.5 * ui.menu.line_height, ui.menu.font_size, 'centerpoint')
end

---------------------------------------

local key_func = { 'up', 'down', 'left', 'right', 'slow', 'shoot', 'spell', 'special', 'repfast', 'repslow', 'menu', 'snapshot' }

key_setting_menu = Class(simple_menu)

function key_setting_menu:init(title, content)
    simple_menu.init(self, title, content)
    self.w = 20
end

function key_setting_menu:frame()
    task.Do(self)
    if self.locked then
        return
    end
    if self.pos_changed > 0 then
        self.pos_changed = self.pos_changed - 1
    end
    local last_key = _GetLastKey()
    if last_key ~= KEY.NULL then
        local item = setting_item[self.pos]
        self.pos_changed = ui.menu.shake_time
        if self.pos <= 12 then
            if self.edit then
                _GetLastKey()
                if self.pos <= 8 then
                    --cur_setting.keys[key_func[self.pos]]=last_key
                    self.key[key_func[self.pos]] = last_key
                elseif self.pos <= 12 then
                    cur_setting.keysys[key_func[self.pos]] = last_key
                end
                self.edit = false
                save_setting()
                return
            end
        end
        --        self.pos=self.pos+1
        --        if self.pos==13 then
        --            self.pos=12
        --            menu.FlyIn(menu_title,'left')
        --            menu.FlyOut(menu_key,'right')
    end

    if not self.edit then
        simple_menu.frame(self)
    end
end

function key_setting_menu:render()
    SetFontState('menu', '', Color(self.alpha * 255, unpack(ui.menu.title_color)))
    RenderText('menu', self.title, self.x, self.y + ui.menu.line_height * 6.5, ui.menu.font_size, 'centerpoint')
    ui.DrawMenu('', self.text, self.pos, self.x - 128, self.y - ui.menu.line_height, self.alpha, self.timer, self.pos_changed, 'left')
    local key_name = {}
    if self.edit then
        if self.timer % 30 < 15 then
            RenderText('menu', '___', self.x + 128, self.y + ui.menu.line_height * (7 - self.pos), ui.menu.font_size, 'right')
        end
    end
    for i = 1, 8 do
        --table.insert(key_name,_key_code_to_name[cur_setting.keys[key_func[i]]])
        table.insert(key_name, _key_code_to_name[self.key[key_func[i]]])
    end
    for i = 9, 12 do
        table.insert(key_name, _key_code_to_name[cur_setting.keysys[key_func[i]]])
    end
    table.insert(key_name, '')
    table.insert(key_name, '')
    ui.DrawMenu('', key_name, self.pos, self.x + 128, self.y - ui.menu.line_height, self.alpha, self.timer, self.pos_changed, 'right')
end

---------------------------------------

other_setting_menu = Class(simple_menu)

function other_setting_menu:init(title, content)
    simple_menu.init(self, title, content)
    self.w = 24
    self.posx = cur_setting.res
end

function other_setting_menu:frame()
    task.Do(self)
    if self.locked then
        return
    end
    local last_key = GetLastKey()
    if last_key ~= KEY.NULL then
        local item = setting_item[self.pos]
        if self.pos >= 5 and self.pos <= 6 then
            if last_key == setting.keys.left then
                cur_setting[item] = max(0, cur_setting[item] - 1)
                PlaySound('select00', 0.003 * cur_setting[item])
            elseif last_key == setting.keys.right then
                cur_setting[item] = min(100, cur_setting[item] + 1)
                PlaySound('select00', 0.003 * cur_setting[item])
            end
        elseif self.pos <= 2 then
            if self.edit then
                if last_key == setting.keys.down then
                    self.posx = self.posx - 1
                    PlaySound('select00', 0.3)
                elseif last_key == setting.keys.up then
                    self.posx = self.posx + 1
                    PlaySound('select00', 0.3)
                elseif last_key == setting.keys.shoot then
                    self.edit = false
                    PlaySound('select00', 0.3)
                elseif last_key == setting.keys.spell then
                    self.edit = false
                    cur_setting.res = menu_other.setting_backup
                    cur_setting.resx = Resolution[cur_setting.res][1]
                    cur_setting.resy = Resolution[cur_setting.res][2]
                    PlaySound('cancel00', 0.3)
                end
                self.posx = max(1, min(self.posx, 5))
                cur_setting.res = self.posx
                cur_setting.resx = Resolution[cur_setting.res][1]
                cur_setting.resy = Resolution[cur_setting.res][2]
                return
            end
            --[[        elseif self.pos<=2 then
                        local step=10^(self.posx-1)
                        if self.edit then
                            if last_key==setting.keys.down then cur_setting[item]=cur_setting[item]-step PlaySound('select00',0.3)
                            elseif last_key==setting.keys.up then cur_setting[item]=cur_setting[item]+step PlaySound('select00',0.3)
                            elseif last_key==setting.keys.left then self.posx=self.posx+1 PlaySound('select00',0.3)
                            elseif last_key==setting.keys.right then self.posx=self.posx-1 PlaySound('select00',0.3)
                            elseif last_key==setting.keys.shoot then self.edit=false PlaySound('select00',0.3)
                            elseif last_key==setting.keys.spell then self.edit=false cur_setting[item]=menu_other.setting_backup PlaySound('cancel00',0.3)
                            end
                            self.posx=max(1,min(self.posx,4))
                            cur_setting[item]=max(1,min(cur_setting[item],9999))
                            return
                        end]]
        elseif self.pos > 2 and self.pos < 5 then
            if last_key == setting.keys.left or last_key == setting.keys.right then
                cur_setting[item] = not cur_setting[item]
                PlaySound('select00', 0.3)
            end
        end
    end
    --    if not cur_setting[setting_item[3]] then
    --[[        cur_setting.res=1
            self.posx=1
            cur_setting.resx=Resolution[1][1]
            cur_setting.resy=Resolution[1][2]
        end]]
    if not self.edit then
        simple_menu.frame(self)
    end
end

function other_setting_menu:render()
    SetFontState('menu', '', Color(self.alpha * 255, unpack(ui.menu.title_color)))
    RenderText('menu', self.title, self.x, self.y + ui.menu.line_height * 4, ui.menu.font_size, 'centerpoint')
    if self.pos <= 2 and self.edit then
        if self.timer % 30 < 15 then
            RenderText('menu', '____', self.x + 128 - (1 - 1) * ui.menu.num_width, self.y + ui.menu.line_height * (3.5 - 1), ui.menu.font_size, 'right')
            RenderText('menu', '____', self.x + 128 - (1 - 1) * ui.menu.num_width, self.y + ui.menu.line_height * (3.5 - 2), ui.menu.font_size, 'right')
        end
    end
    ui.DrawMenu('', self.text, self.pos, self.x - 128, self.y - ui.menu.line_height, self.alpha, self.timer, self.pos_changed, 'left')
    local setting_text = {}
    for i = 1, 6 do
        setting_text[i] = tostring(cur_setting[setting_item[i]])
    end
    setting_text[7] = ''
    ui.DrawMenu('', setting_text, self.pos, self.x + 128, self.y - ui.menu.line_height, self.alpha, self.timer, self.pos_changed, 'right')
end

---------------------------------------
local function enumMods()
    local list = {}
    local pos = 1
    if FindFiles then
        local list_mods = FindFiles('mod\\', 'zip', '')
        for i, v in ipairs(list_mods) do
            local filename = v[1]
            local mod_name = string.sub(filename, 5, -5)
            if mod_name ~= 'launcher' then
                table.insert(list, mod_name)
            end
            if cur_setting.mod == mod_name then
                pos = #list
            end
        end
    else
        for mod_fn in lfs.dir('mod\\') do
            if lfs.attributes('mod\\' .. mod_fn, 'mode') ~= 'directory' and string.sub(mod_fn, -4, -1) == '.zip' and mod_fn ~= 'launcher.zip' then
                local mod_name = string.sub(mod_fn, 1, -5)
                table.insert(list, mod_name)
                if cur_setting.mod == mod_name then
                    pos = #list
                end
            end
        end
    end
    return list, pos
end
local function setMod(mod_name)
    cur_setting.mod = mod_name
    save_setting()
    start_game()
end

simple_menu_mod = Class(object)

function simple_menu_mod:init(title, content)
    self.layer = LAYER_TOP
    self.group = GROUP_GHOST
    self.alpha = 1
    self.x = screen.width * 0.5 - 448
    self.y = screen.height * 0.5
    self.bound = false
    self.locked = true
    self.title = title
    self.text = {}
    self.func = {}
    for i = 1, #content do
        self.text[i] = content[i][1]
        self.func[i] = content[i][2]
    end
    self.pos = 1
    self.pos_pre = 1
    self.pos_changed = 0
    if content[#content][1] == 'exit' then
        self.exit_func = content[#content][2]
        self.text[#content] = nil
        self.func[#content] = nil
    end
    self.mods, self.last_mod = enumMods()
    self.pos = self.last_mod
    self._list, self._pos = sp.GetListSection(self.mods, 18, self.pos, 10)
end

function simple_menu_mod:frame()
    task.Do(self)
    if self.locked then
        return
    end
    local enable = (#self.mods > 0)
    if enable then
        if GetLastKey() == setting.keys.up then
            self.pos = self.pos - 1
            PlaySound('select00', 0.3)
        end
        if GetLastKey() == setting.keys.down then
            self.pos = self.pos + 1
            PlaySound('select00', 0.3)
        end
        self.pos = (self.pos - 1 + #(self.mods)) % (#(self.mods)) + 1
    else
        self.pos = 1
    end
    if enable and KeyIsPressed 'shoot' then
        setMod(self.mods[self.pos])
        PlaySound('ok00', 0.3)
    elseif KeyIsPressed 'spell' and self.exit_func then
        self.exit_func()
        PlaySound('cancel00', 0.3)
    end
    if self.pos_changed > 0 then
        self.pos_changed = self.pos_changed - 1
    end
    if self.pos_pre ~= self.pos then
        self.pos_changed = ui.menu.shake_time
    end
    self.pos_pre = self.pos
    self.mods, self.last_mod = enumMods()
    self._list, self._pos = sp.GetListSection(self.mods, 18, self.pos, 10)
end

function simple_menu_mod:render()
    DrawMOD(self.title, self._list, self._pos, self.x, self.y, self.alpha, self.timer, self.pos_changed)
end

function DrawMOD(title, text, pos, x, y, alpha, timer, shake, align)
    align = align or 'center'
    local yos
    local ii = 0
    if pos > 19 then
        ii = pos - 19
    else
        ii = 0
    end
    if title == '' then
        yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
    else
        yos = min((#text - 1) * ui.menu.sc_pr_line_height * 0.5, 198)
        SetFontState('menu', '', Color(alpha * 255, unpack(ui.menu.title_color)))
        RenderText('menu', title, x, y + yos + ui.menu.line_height, ui.menu.font_size, align, 'vcenter')
    end
    for i = 1, #text do
        if i == pos then
            local color = {}
            local k = cos(timer * ui.menu.blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
            end
            local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
            SetFontState('menu', '', Color(alpha * 255, unpack(color)))
            RenderText('menu', text[i], x + xos, y - min(i, 19) * ui.menu.sc_pr_line_height + yos, ui.menu.font_size, align, 'vcenter')
        elseif i < 20 and i ~= pos then
            SetFontState('menu', '', Color(alpha * 255, unpack(ui.menu.unfocused_color)))
            RenderText('menu', text[min(i + ii, #text)], x, y - i * ui.menu.sc_pr_line_height + yos, ui.menu.font_size, align, 'vcenter')
        end
    end
end

function DrawMODTTF(title, text, pos, x, y, alpha, timer, shake, align)
    align = align or 'center'
    local yos
    local ii = 0
    if pos > 19 then
        ii = pos - 19
    else
        ii = 0
    end
    if title == '' then
        yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
    else
        yos = min((#text - 1) * ui.menu.sc_pr_line_height * 0.5, 198)
        SetFontState('menu', '', Color(alpha * 255, unpack(ui.menu.title_color)))
        RenderText('menu', title, x, y + yos + ui.menu.line_height, ui.menu.font_size, align, 'vcenter')
    end
    for i = 1, #text do
        if i == pos then
            local color = {}
            local k = cos(timer * ui.menu.blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
            end
            local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
            RenderTTF('menuttfs', text[i], x + xos + 1, x + xos + 1, y - i * ui.menu.sc_pr_line_height + yos - 1, y - i * ui.menu.sc_pr_line_height + yos - 1, Color(alpha * 255, 0, 0, 0), align, 'vcenter', 'noclip')
            RenderTTF('menuttfs', text[i], x + xos, x + xos, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(alpha * 255, unpack(color)), align, 'vcenter', 'noclip')
        elseif i < 20 and i ~= pos then
            RenderTTF('menuttfs', text[i], x + 1, x + 1, y - i * ui.menu.sc_pr_line_height + yos - 1, y - i * ui.menu.sc_pr_line_height + yos - 1, Color(alpha * 255, 0, 0, 0), align, 'vcenter', 'noclip')
            RenderTTF('menuttfs', text[i], x, x, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(alpha * 255, 192, 192, 192), align, 'vcenter', 'noclip')
        end
    end
end

---------------------------------------

_plugin_manager_menu = Class(object)

function _plugin_manager_menu:init(exit_func)
    self.layer = LAYER_TOP
    self.group = GROUP_GHOST
    self.alpha = 1
    self.x = screen.width * 0.5 - screen.width
    self.y = screen.height * 0.5
    self.bound = false
    self.locked = true
    self.title = "Plugin Manager"
    self.pos = 1
    self.pos_pre = 1
    self.pos_changed = 0
    self.edit = false

    self._list, self._pos = {}, 0

    self.exit_func = exit_func

    self.plugins = {}
    _plugin_manager_menu.refresh(self)
end

function _plugin_manager_menu:frame()
    task.Do(self)
    if self.locked then
        return
    end

    _plugin_manager_menu.sort(self)
    --op
    if KeyPress("slow") then
        self.edit = true
        --pos
        --查找启用的插件数量
        local enableN = 0
        for i, v in ipairs(self.plugins) do
            if v[3] then
                enableN = i
            else
                break
            end
        end
        if enableN > 1 then
            --只对一个进行排序是没有用的
            --判断pos位置，防止越界
            if GetLastKey() == setting.keys.up and self.pos > 1 then
                local tmp = self.plugins[self.pos]
                self.plugins[self.pos] = self.plugins[self.pos - 1]
                self.plugins[self.pos - 1] = tmp
                self.pos = self.pos - 1
                PlaySound('select00', 0.3)
            elseif GetLastKey() == setting.keys.down and self.pos < enableN then
                --只对启用的插件进行排序
                local tmp = self.plugins[self.pos]
                self.plugins[self.pos] = self.plugins[self.pos + 1]
                self.plugins[self.pos + 1] = tmp
                self.pos = self.pos + 1
                PlaySound('select00', 0.3)
            end
        end
    else
        self.edit = false
        --pos
        if GetLastKey() == setting.keys.up then
            self.pos = self.pos - 1
            PlaySound('select00', 0.3)
        elseif GetLastKey() == setting.keys.down then
            self.pos = self.pos + 1
            PlaySound('select00', 0.3)
        end
        self.pos = (self.pos - 1 + #(self.plugins)) % (#(self.plugins)) + 1
        --op
        if KeyIsPressed 'shoot' then
            if not (self.plugins[self.pos][3]) then
                --从启用到禁用，插件跳转到启用队列，pos前移
                for i, v in ipairs(self.plugins) do
                    --寻找禁用队列中队首的pos
                    if not (v[3]) then
                        self.plugins[self.pos][3] = not (self.plugins[self.pos][3])
                        self.pos = i
                        break
                    end
                end
            else
                --从启用到禁用，插件跳转到禁用队列，pos后移
                for i = #self.plugins, 1, -1 do
                    --寻找启用队列中队尾的pos
                    if self.plugins[i][3] then
                        self.plugins[self.pos][3] = not (self.plugins[self.pos][3])
                        self.pos = i
                        break
                    end
                end
            end
            PlaySound('ok00', 0.3)
        elseif KeyIsPressed 'spell' and self.exit_func then
            self.exit_func(self)
            PlaySound('cancel00', 0.3)
        end
    end
    --after op
    if self.pos_changed > 0 then
        self.pos_changed = self.pos_changed - 1
    end
    if self.pos_pre ~= self.pos then
        self.pos_changed = ui.menu.shake_time
    end
    self.pos_pre = self.pos
    self._list, self._pos = sp.GetListSection(self.plugins, 18, self.pos, 10)
end

function _plugin_manager_menu:render()
    _plugin_manager_menu.DrawPlugins(self.title, self._list, self._pos, self.x, self.y, self.alpha, self.timer, self.pos_changed, self.edit)
end

function _plugin_manager_menu.DrawPlugins(title, text, pos, x, y, alpha, timer, shake, edit)
    align = align or 'center'
    local yos
    local ii = 0
    if pos > 19 then
        ii = pos - 19
    else
        ii = 0
    end
    if title == '' then
        yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
    else
        yos = min((#text - 1) * ui.menu.sc_pr_line_height * 0.5, 198)
        SetFontState('menu', '', Color(alpha * 255, unpack(ui.menu.title_color)))
        RenderText('menu', title, x, y + yos + ui.menu.line_height, ui.menu.font_size, align, 'vcenter')
    end
    for i = 1, #text do
        local posnfmt = string.format("%02d.", i)
        if i == pos then
            local color = {}
            local k = cos(timer * ui.menu.blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
            end
            local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
            if not edit then
                SetFontState('menu', '', Color(alpha * 255, unpack(color)))
            else
                SetFontState('menu', '', Color(alpha * 255, 0, 255, 255))
            end
            local shoutext = text[i][1]
            if #shoutext > 18 then
                --shoutext=string.sub(shoutext,1,16).."..."
            end
            RenderText('menu',
                    posnfmt .. shoutext,
                    x + xos - (screen.width * 0.5) + 16,
                    y - min(i, 19) * ui.menu.sc_pr_line_height + yos,
                    ui.menu.font_size, 'left', 'vcenter'
            )
            if text[i][3] then
                RenderText('menu',
                        "Enable",
                        x + xos + (screen.width * 0.5) - 16,
                        y - min(i, 19) * ui.menu.sc_pr_line_height + yos,
                        ui.menu.font_size, 'right', 'vcenter'
                )
            else
                RenderText('menu',
                        "Disable",
                        x + xos + (screen.width * 0.5) - 16,
                        y - min(i, 19) * ui.menu.sc_pr_line_height + yos,
                        ui.menu.font_size, 'right', 'vcenter'
                )
            end
        elseif i < 20 and i ~= pos then
            --state
            local state = "Unkown"
            if text[min(i + ii, #text)][3] then
                state = "Enable"
                SetFontState('menu', '', Color(alpha * 255, 128, 128, 128))
            else
                state = "Disable"
                SetFontState('menu', '', Color(alpha * 255, 80, 80, 80))
            end
            RenderText('menu',
                    state,
                    x + (screen.width * 0.5) - 16,
                    y - i * ui.menu.sc_pr_line_height + yos,
                    ui.menu.font_size, 'right', 'vcenter'
            )
            --plugin name
            --SetFontState('menu','',Color(alpha*255,128,128,128))
            local shoutext = text[min(i + ii, #text)][1]
            if #shoutext > 18 then
                --shoutext=string.sub(shoutext,1,16).."..."
            end
            RenderText('menu',
                    posnfmt .. shoutext,
                    x - (screen.width * 0.5) + 16,
                    y - i * ui.menu.sc_pr_line_height + yos,
                    ui.menu.font_size, 'left', 'vcenter'
            )
        end
    end
end

--禁用的排在后面
function _plugin_manager_menu:sort()
    local ret = {}
    for _, v in ipairs(self.plugins) do
        if v[3] then
            table.insert(ret, v)
        end
    end
    for _, v in ipairs(self.plugins) do
        if not (v[3]) then
            table.insert(ret, v)
        end
    end
    self.plugins = ret
end

--每次菜单飞入时刷新一次
function _plugin_manager_menu:refresh()
    self.plugins = lstg.plugin.LoadConfig()
    self.plugins = lstg.plugin.FreshConfig(self.plugins)
    lstg.plugin.SaveConfig(self.plugins)
end

--每次菜单飞出时保存一次
function _plugin_manager_menu:save()
    lstg.plugin.SaveConfig(self.plugins)
end

---------------------------------------

function start_game()
    loadConfigure()
    LoadPack('mod\\' .. setting.mod .. '.zip')
    SetSplash(false)
    SetTitle(setting.mod)
    if not ChangeVideoMode(setting.resx, setting.resy, setting.windowed, setting.vsync) then
        if lfs.attributes('.\\LuaSTGPlus.dev.exe') ~= nil then
            os.execute('start /b .\\LuaSTGPlus.dev.exe "start_game=true"')
        else
            os.execute('start /b .\\LuaSTGPlus.exe "start_game=true"')
        end
        stage.QuitGame()
        return
    end
    SetSEVolume(setting.sevolume / 100)
    SetBGMVolume(setting.bgmvolume / 100)
    ResetScreen()--Lscreen
    SetResourceStatus 'global'
    --ResetUI()
    Include("root.lua")
    SetResourceStatus 'stage'
    InitAllClass()--Lobject
    InitScoreData()--initialize score data--Lscoredata
    ext.reload()
    CHXuiLib.LoadUIScheme(CHXuiLib.Scheme.game)
    stage.Set('init', 'none')
end
