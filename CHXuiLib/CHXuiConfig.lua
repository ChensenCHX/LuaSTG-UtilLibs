local tex, img, ani, bgm, snd, ps, fnt, ttf, fx = 1, 2, 3, 4, 5, 6, 7, 8, 9

local UIScheme = {
    {"UI", "drawBase", function(self)
        local w = lstg.world
        local x = (w.scrr - w.scrl) / 2 + w.scrl
        local y = (w.scrt - w.scrb) / 2 + w.scrb
        local hs = (w.scrr - w.scrl) / 384
        local vs = (w.scrt - w.scrb) / 448
        x = x + 96 * hs
        if CheckRes("img", "image:UI_img") then
            Render("image:UI_img", x, y, 0, hs, vs)
        else
            Render("ui_bg", x, y, 0, hs, vs)
        end
        if CheckRes("img", "image:LOGO_img") then
            Render("image:LOGO_img", -16 + w.scrr, 150, 0, 0.5, 0.5)
        else
            Render("logo", -16 + w.scrr, 150, 0, 0.5, 0.5)
        end
        SetFontState("menu", "", Color(0xFFFFFFFF))
        RenderText("menu",
                string.format("%.1ffps", GetFPS()),
                220 + w.scrr, 1, 0.25, "right", "bottom")
    end},

    {"UI", "drawDifficulty", function(self)
        if not stage.current_stage.name then return end
        SetFontState("score3", "", Color(0xFFADADAD))
        local w = lstg.world
        local diff = string.match(stage.current_stage.name, "[%w_][%w_ ]*$")
        local diffimg = CheckRes("img", "image:diff_" .. diff)
        if diffimg then
            Render("image:diff_" .. diff, 112 + w.scrr, 448)
        else
            --by OLC，难度显示加入符卡练习
            if ext.sc_pr and diff == "Spell Practice" and lstg.var.sc_index then
                diff = _editor_class[_sc_table[lstg.var.sc_index][1]].difficulty
                if diff == "All" then
                    diff = "SpellCard"
                end
            end
            local x1 = -192 + w.scrr
            local x2 = 112 + w.scrr
            local y1 = 457
            local y2 = 448
            local dy = 22
            local s = stage.current_stage
            local timer = s.timer
            local a, t = 255, 1
            local x, y = x2, y2
            if lstg.var.is_parctice or s.number == 1 then
                if timer < 60 then
                    x, y = x1, y1
                    dy = 11
                    a = int(timer / 4) % 2 * 255
                elseif timer >= 60 and timer < 150 then
                    x, y = x1, y1
                    dy = 11
                elseif timer >= 150 and timer < 158 then
                    x, y = x1, y1
                    dy = 11
                    t = max((1 - (timer - 150) / 8), 0)
                    a = t * 255
                elseif timer >= 158 and timer < 165 then
                    t = min((timer - 158) / 9, 1)
                    a = t * 255
                end
            end
            if diff == "Easy" or diff == "Normal" or diff == "Hard" or diff == "Lunatic" or diff == "Extra" then
                SetImageState("rank_" .. diff, "", Color(a, 255, 255, 255))
                Render("rank_" .. diff, x, y, 0, 0.5, t * 0.5)
            else
                SetFontState("menu", "", Color(a, 255, 255, 255))
                RenderText("menu", diff, x, y + dy, 0.5, "center")
            end
        end
    end},

    {"UI", "ScoreUpdate", function(self)
        if not stage.current_stage.name then return end
        local var = lstg.var
        if not var.score then return end
        local cur_score = var.score
        local score = self.score or cur_score
        local score_tmp = self.score_tmp or cur_score
        if score_tmp < cur_score then
            if cur_score - score_tmp <= 100 then
                score = score + 10
            elseif cur_score - score_tmp <= 1000 then
                score = score + 100
            else
                score = int(score / 10 + int((cur_score - score_tmp) / 600)) * 10 + cur_score % 10
            end
        end
        if score_tmp > cur_score then
            score_tmp = cur_score
            score = cur_score
        end
        if score >= cur_score then
            score_tmp = cur_score
            score = cur_score
        end
        self.score = score
        self.score_tmp = score_tmp
    end},

    {"UI", "drawInfo1", function(self)
        if not stage.current_stage.name then return end
        local w = lstg.world
        local RenderImgList = {
            { "line_1", 109 + w.scrr, 419, 0, 1, 1 },
            { "line_2", 109 + w.scrr, 397, 0, 1, 1 },
            { "line_3", 109 + w.scrr, 349, 0, 1, 1 },
            { "line_4", 109 + w.scrr, 311, 0, 1, 1 },
            { "line_5", 109 + w.scrr, 247, 0, 1, 1 },
            { "line_6", 109 + w.scrr, 224, 0, 1, 1 },
            { "line_7", 109 + w.scrr, 202, 0, 1, 1 },
            { "hint.hiscore", 12 + w.scrr, 425, 0, 1, 1 },
            { "hint.score", 12 + w.scrr, 403, 0, 1, 1 },
            { "hint.Pnumber", 12 + w.scrr, 371, 0, 1, 1 },
            { "hint.Bnumber", 12 + w.scrr, 334, 0, 1, 1 },
            { "hint.Cnumber", 138 + w.scrr, 316, 0, 0.85, 0.85 },
            { "hint.Cnumber", 138 + w.scrr, 354, 0, 0.85, 0.85 },
            { "hint.power", 39 + w.scrr, 253, 0, 0.5, 0.5 },
            { "hint.point", 39 + w.scrr, 230, 0, 0.5, 0.5 },
            { "hint.graze", 54 + w.scrr, 208, 0, 0.5, 0.5 }
        }
        local s = stage.current_stage
        local timer = s.timer
        local alplat
        if (lstg.var.is_parctice or s.number == 1) and timer < 448 then
            local alpharate = 4
            local alphatrate = 1
            local timerrate = 3
            local y0 = 448 - timer * timerrate
            local dyt = max(300 - y0, 0)
            for i = 1, #RenderImgList do
                local p1, p2, p3, p4, p5, p6 = unpack(RenderImgList[i])
                local dy = max(p3 - y0, 0)
                local alpha = min(dy * alpharate, 255)
                local dw = 1
                if string.find(p1, "line_") then
                    dw = alpha / 255
                end
                SetImageState(p1, "", Color(alpha, 255, 255, 255))
                Render(p1, p2, p3, p4, p5 * dw, p6)
            end
            alplat = min(dyt * alphatrate, 255)
        else
            for i = 1, #RenderImgList do
                local p1, p2, p3, p4, p5, p6 = unpack(RenderImgList[i])
                SetImageState(p1, "", Color(255, 255, 255, 255))
                Render(p1, p2, p3, p4, p5, p6)
            end
            alplat = 255
        end
        SetFontState("score3", "", Color(alplat, 173, 173, 173))
        RenderScore("score3", max(lstg.tmpvar.hiscore or 0, self.score or 0), 216 + w.scrr, 436, 0.43, "right")
        SetFontState("score3", "", Color(alplat, 255, 255, 255))
        RenderScore("score3", self.score or 0, 216 + w.scrr, 414, 0.43, "right")
        RenderText("score3", string.format("%d/5", lstg.var.chip), 214 + w.scrr, 361, 0.35, "right")
        RenderText("score3", string.format("%d/5", lstg.var.bombchip), 214 + w.scrr, 323, 0.35, "right")
        SetFontState("score1", "", Color(alplat, 205, 102, 0))
        SetFontState("score2", "", Color(alplat, 34, 216, 221))
        RenderText("score1", string.format("%d.    /4.    ", math.floor(lstg.var.power / 100)), 204 + w.scrr, 262, 0.4, "right")
        RenderText("score1", string.format("      %d%d        00", math.floor((lstg.var.power % 100) / 10), lstg.var.power % 10), 205 + w.scrr, 258.5, 0.3, "right")
        RenderScore("score2", lstg.var.pointrate, 204 + w.scrr, 239, 0.4, "right")
        SetFontState("score3", "", Color(alplat, 173, 173, 173))
        RenderText("score3", string.format("%d", lstg.var.graze), 204 + w.scrr, 216, 0.4, "right")
        SetImageState("hint.life", "", Color(alplat, 255, 255, 255))
        for i = 1, 8 do
            Render("hint.life", 89 + w.scrr + 13 * i, 371, 0, 1, 1)
        end
        SetImageState("hint.lifeleft", "", Color(alplat, 255, 255, 255))
        for i = 1, lstg.var.lifeleft do
            Render("hint.lifeleft", 89 + w.scrr + 13 * i, 371, 0, 1, 1)
        end
        SetImageState("hint.bomb", "", Color(alplat, 255, 255, 255))
        for i = 1, 8 do
            Render("hint.bomb", 89 + w.scrr + 13 * i, 334, 0, 1, 1)
        end
        SetImageState("hint.bombleft", "", Color(alplat, 255, 255, 255))
        for i = 1, lstg.var.bomb do
            Render("hint.bombleft", 89 + w.scrr + 13 * i, 334, 0, 1, 1)
        end
        local Lchip = lstg.var.chip
        if Lchip > 0 and Lchip < 5 and lstg.var.lifeleft < 8 then
            SetImageState("lifechip" .. Lchip, "", Color(alplat, 255, 255, 255))
            Render("lifechip" .. Lchip, 89 + w.scrr + 13 * (lstg.var.lifeleft + 1), 371, 0, 1, 1)
        end
        local Bchip = lstg.var.bombchip
        if Bchip > 0 and Bchip < 5 and lstg.var.bomb < 8 then
            SetImageState("bombchip" .. Bchip, "", Color(alplat, 255, 255, 255))
            Render("bombchip" .. Bchip, 89 + w.scrr + 13 * (lstg.var.bomb + 1), 334, 0, 1, 1)
        end
        SetFontState("score3", "", Color(alplat, 173, 173, 173))
        RenderScore("score3", max(lstg.tmpvar.hiscore or 0, self.score or 0), 216 + w.scrr, 436, 0.43, "right")
        SetFontState("score3", "", Color(alplat, 255, 255, 255))
        RenderScore("score3", self.score or 0, 216 + w.scrr, 414, 0.43, "right")
        RenderText("score3", string.format("%d/5", lstg.var.chip), 214 + w.scrr, 361, 0.35, "right")
        RenderText("score3", string.format("%d/5", lstg.var.bombchip), 214 + w.scrr, 323, 0.35, "right")
        SetFontState("score1", "", Color(alplat, 205, 102, 0))
        SetFontState("score2", "", Color(alplat, 34, 216, 221))
        RenderText("score1", string.format("%d.    /4.    ", math.floor(lstg.var.power / 100)), 204 + w.scrr, 262, 0.4, "right")
        RenderText("score1", string.format("      %d%d        00", math.floor((lstg.var.power % 100) / 10), lstg.var.power % 10), 205 + w.scrr, 258.5, 0.3, "right")
        RenderScore("score2", lstg.var.pointrate, 204 + w.scrr, 239, 0.4, "right")
        SetFontState("score3", "", Color(alplat, 255, 255, 255))
        RenderText("score3", string.format("%d", lstg.var.graze), 204 + w.scrr, 216, 0.4, "right")
    end},

    Resource = {
        ["boss_ui"] = tex,
        ["boss_spell_name_bg"] = img,
        ["boss_pointer"] = img,
        ["boss_sc_left"] = img,
        ["hint"] = tex,
        ["hint.bonusfail"] = img,
        ["hint.getbonus"] = img,
        ["hint.extend"] = img,
        ["hint.power"] = img,
        ["hint.graze"] = img,
        ["hint.point"] = img,
        ["hint.life"] = img,
        ["hint.lifeleft"] = img,
        ["hint.bomb"] = img,
        ["hint.bombleft"] = img,
        ["kill_time"] = img,
        ["lifechip1"] = img,
        ["lifechip2"] = img,
        ["lifechip3"] = img,
        ["lifechip4"] = img,
        ["bombchip1"] = img,
        ["bombchip2"] = img,
        ["bombchip3"] = img,
        ["bombchip4"] = img,
        ["hint.hiscore"] = img,
        ["hint.score"] = img,
        ["hint.Pnumber"] = img,
        ["hint.Bnumber"] = img,
        ["hint.Cnumber"] = img,
        ["line"] = tex,
        ["line_1"] = img,
        ["line_2"] = img,
        ["line_3"] = img,
        ["line_4"] = img,
        ["line_5"] = img,
        ["line_6"] = img,
        ["line_7"] = img,
        ["ui_rank"] = tex,
        ["rank_Easy"] = img,
        ["rank_Normal"] = img,
        ["rank_Hard"] = img,
        ["rank_Lunatic"] = img,
        ["rank_Extra"] = img,
        ["logo"] = img,
        ["ui_bg"] = img,
        ["menu_bg"] = img
    },

    Resources = function()
        LoadTexture("boss_ui", "THlib/UI/boss_ui.png")
        LoadImage("boss_spell_name_bg", "boss_ui", 0, 0, 256, 36)
        SetImageCenter("boss_spell_name_bg", 256, 0)

        LoadImage("boss_pointer", "boss_ui", 0, 64, 48, 16)
        SetImageCenter("boss_pointer", 24, 0)

        LoadImage("boss_sc_left", "boss_ui", 64, 64, 32, 32)
        SetImageState("boss_sc_left", "", Color(0xFF80FF80))

        LoadTexture("hint", "THlib/UI/hint.png", true)
        LoadImage("hint.bonusfail", "hint", 0, 64, 256, 64)
        LoadImage("hint.getbonus", "hint", 0, 128, 396, 64)
        LoadImage("hint.extend", "hint", 0, 192, 160, 64)
        LoadImage("hint.power", "hint", 0, 12, 84, 32)
        LoadImage("hint.graze", "hint", 86, 12, 74, 32)
        LoadImage("hint.point", "hint", 160, 12, 120, 32)
        LoadImage("hint.life", "hint", 288, 0, 16, 15)
        LoadImage("hint.lifeleft", "hint", 304, 0, 16, 15)
        LoadImage("hint.bomb", "hint", 320, 0, 16, 16)
        LoadImage("hint.bombleft", "hint", 336, 0, 16, 16)
        LoadImage("kill_time", "hint", 232, 200, 152, 56, 16, 16)
        SetImageCenter("hint.power", 0, 16)
        SetImageCenter("hint.graze", 0, 16)
        SetImageCenter("hint.point", 0, 16)
        LoadImageGroup("lifechip", "hint", 288, 16, 16, 15, 4, 1, 0, 0)
        LoadImageGroup("bombchip", "hint", 288, 32, 16, 16, 4, 1, 0, 0)
        LoadImage("hint.hiscore", "hint", 424, 8, 80, 20)
        LoadImage("hint.score", "hint", 424, 30, 64, 20)
        LoadImage("hint.Pnumber", "hint", 352, 8, 56, 20)
        LoadImage("hint.Bnumber", "hint", 352, 30, 72, 20)
        LoadImage("hint.Cnumber", "hint", 352, 52, 40, 20)
        SetImageCenter("hint.hiscore", 0, 10)
        SetImageCenter("hint.score", 0, 10)
        SetImageCenter("hint.Pnumber", 0, 10)
        SetImageCenter("hint.Bnumber", 0, 10)

        LoadTexture("line", "THlib/UI/line.png", true)
        LoadImageGroup("line_", "line", 0, 0, 200, 8, 1, 7, 0, 0)

        LoadTexture("ui_rank", "THlib/UI/rank.png")
        LoadImage("rank_Easy", "ui_rank", 0, 0, 144, 32)
        LoadImage("rank_Normal", "ui_rank", 0, 32, 144, 32)
        LoadImage("rank_Hard", "ui_rank", 0, 64, 144, 32)
        LoadImage("rank_Lunatic", "ui_rank", 0, 96, 144, 32)
        LoadImage("rank_Extra", "ui_rank", 0, 128, 144, 32)

        LoadImageFromFile("logo", "THlib\\UI\\logo.png")
        SetImageCenter("logo", 0, 0)
        LoadImageFromFile("ui_bg", "THlib\\UI\\ui_bg.png")
        LoadImageFromFile("menu_bg", "THlib\\UI\\menu_bg.png")
    end
}

local LaunchScheme = {
    {"UI", "drawBG", function(self)
        Render("menu_bg2", 198, 264)
        SetFontState("menu", "", Color(0xFFFFFFFF))
        RenderText("menu",
            string.format("%.1ffps", GetFPS()),
            392, 1, 0.25, "right", "bottom")
    end},

    Resource = {
        ["menu_bg2"] = tex,
    },

    Resources = function()
        LoadImageFromFile("menu_bg2", "THlib\\UI\\menu_bg_2.png")
    end
}

CHXuiLib.Scheme = {game = UIScheme, launcher = LaunchScheme}