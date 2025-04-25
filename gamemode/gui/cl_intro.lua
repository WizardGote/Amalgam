local introTexts = {
    "Build your own world",
    "Craft your own experience",
    "Define your own mechanics",
    "The canvas is yours to paint",
    "Let your creation unfold"
}

local currentTextIndex = 1
local typedText = ""
local typingIndex = 0
local isTyping = true
local isDeleting = false
local typingSpeed = 0.06
local nextCharTime = 0

local bgAlpha = 255
local logoAlpha = 0
local displayTime = 7
local fadeSpeed = 150
local canSpawn = false
local introStarted = false
local introStartTime = 0
local music

local bgColor = Color(235, 235, 235)
local gradientColor = Color(210, 210, 210)
local gradientMat = Material("vgui/gradient_down")
local smokeMat = Material("particle/smokestack")
local logoMat = Material("amalgam/amalgam_logo.png", "smooth")

local function PlayTickSound()
    if (not IsValid(LocalPlayer())) then return end

    local dummy = ClientsideModel("models/props_junk/PopCan01a.mdl")
    if (not IsValid(dummy)) then return end

    dummy:SetNoDraw(true)
    dummy:SetPos(LocalPlayer():GetPos())

    local snd = CreateSound(dummy, "amalgam/tick1.ogg")
    if (snd) then
        snd:ChangePitch(math.random(80, 110), 0)
        snd:ChangeVolume(0.5, 0)
        snd:Play()
        snd:FadeOut(0.2)
    end

    timer.Simple(2, function()
        if (IsValid(dummy)) then
            dummy:Remove()
        end
    end)
end

local function SplitFirstWord(str)
    local first, rest = str:match("^(%S+)%s+(.*)$")
    return first or str, rest or ""
end

function Amalgam:DrawIntroScreen()
    if (not introStarted) then return end
    if (canSpawn and bgAlpha <= 0) then return end
    local scrW, scrH = ScrW(), ScrH()
    bgColor.a = bgAlpha
    gradientColor.a = bgAlpha
    surface.SetDrawColor(bgColor)
    surface.DrawRect(0, 0, scrW, scrH)
    surface.SetDrawColor(gradientColor)
    surface.SetMaterial(gradientMat)
    surface.DrawTexturedRect(0, 0, scrW, scrH)
    surface.SetMaterial(smokeMat)
    surface.SetDrawColor(220, 220, 220, math.Clamp(bgAlpha * 0.25, 0, 100))
    local scroll = (CurTime() * 30) % scrH
    for i = 0, 2 do
        surface.DrawTexturedRectUV(0, scrH - scroll + (i * 256), scrW, 256, 0, 0, 1, 1)
    end
    if (logoAlpha > 0) then
        local logoScale = 3.2
        local baseW, baseH = 256, 128
        local logoW, logoH = baseW * logoScale, baseH * logoScale
        surface.SetDrawColor(255, 255, 255, logoAlpha)
        surface.SetMaterial(logoMat)
        surface.DrawTexturedRect((scrW - logoW) / 2, scrH * 0.15 - 16, logoW, logoH)
    end
    if (not canSpawn) then
        local text = typedText or ""
        local first, rest = SplitFirstWord(text)
        surface.SetFont("Amalgam.IntroFont")
        local firstW = surface.GetTextSize(first)
        local restW = surface.GetTextSize(" " .. rest)
        local totalW = firstW + restW
        local x = scrW / 2 - totalW / 2
        local y = scrH - 100
        local t = CurTime()
        local pulse = math.sin(t * 2) * 25
        local orangePulse = Color(255, 140 + pulse, 0)
        local white = Color(255, 255, 255)
        local stroke = Color(0, 0, 0, 50)
        draw.SimpleTextOutlined(first, "Amalgam.IntroFont", x, y, orangePulse, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, stroke)
        draw.SimpleTextOutlined(" " .. rest, "Amalgam.IntroFont", x + firstW, y, white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, stroke)
    end
end

hook.Add("HUDPaint", "DrawGameIntro", function()
    Amalgam:DrawIntroScreen()
end)

local function StartLogoFadeIn()
    local fadeTarget = 255
    local duration = 30
    local step = fadeTarget / (duration / 0.01)
    timer.Create("LogoFadeIn", 0.01, 0, function()
        logoAlpha = math.Clamp(logoAlpha + step, 0, 255)
        if (logoAlpha >= 255) then
            timer.Remove("LogoFadeIn")
        end
    end)
end

function Amalgam:RunIntroSequence()
    introStarted = true
    canSpawn = false
    currentTextIndex = 1
    typedText = ""
    typingIndex = 0
    isTyping = true
    isDeleting = false
    nextCharTime = CurTime() + typingSpeed
    introStartTime = CurTime()
    logoAlpha = 0
    gui.EnableScreenClicker(false)
    RunConsoleCommand("dsp_volume", "0")
    StartLogoFadeIn()
  
    timer.Simple(0, function()
        if IsValid(LocalPlayer()) then
            LocalPlayer():SetNWBool("IntroActive", true)
        end
    end)
  
  	net.Start("nIntroWatched")
    net.SendToServer()
  
    if (music) then
        music:Stop()
    end
  
    sound.PlayFile("sound/amalgam/intro.mp3", "noplay", function(station)
        if (IsValid(station)) then
            music = station
            music:SetVolume(1)
            music:Play()
        end
    end)
  
    timer.Create("IntroTypingLogic", 0.01, 0, function()
        local fullText = introTexts[currentTextIndex] or ""
        if (isTyping and CurTime() >= nextCharTime) then
            typingIndex = typingIndex + 1
            typedText = string.sub(fullText, 1, typingIndex)
            nextCharTime = CurTime() + typingSpeed
            PlayTickSound()
            if (typingIndex >= #fullText) then
                isTyping = false
                timer.Simple(displayTime, function()
                    isDeleting = true
                    nextCharTime = CurTime() + typingSpeed
                end)
            end
        elseif (isDeleting and CurTime() >= nextCharTime) then
            typingIndex = typingIndex - 1
            typedText = string.sub(fullText, 1, typingIndex)
            nextCharTime = CurTime() + typingSpeed
            PlayTickSound()
            if (typingIndex <= 0) then
                isDeleting = false
                currentTextIndex = currentTextIndex + 1
                if (currentTextIndex > #introTexts) then
                    canSpawn = true
                    timer.Remove("IntroTypingLogic")
                    if (music) then
                        local fadeTime = 2
                        local volume = 1
                        timer.Create("MusicFadeOut", 0.1, fadeTime * 10, function()
                            if (music) then
                                volume = math.Clamp(volume - 0.1, 0, 1)
                                music:SetVolume(volume)
                                if (volume <= 0) then
                                    music:Stop()
                                    music = nil
                                    timer.Remove("MusicFadeOut")
                                end
                            end
                        end)
                    end
                    timer.Create("BackgroundFadeOut", 0.01, 0, function()
                        local fade = fadeSpeed * FrameTime()
                        bgAlpha = math.Clamp(bgAlpha - fade, 0, 255)
                        logoAlpha = math.Clamp(logoAlpha - fade, 0, 255)
                        if (bgAlpha <= 0 and logoAlpha <= 0) then
                            introStarted = false
                            hook.Remove("HUDPaint", "DrawGameIntro")
                            timer.Remove("BackgroundFadeOut")
                            gui.EnableScreenClicker(false)
							input.SetCursorPos(ScrW() / 2, ScrH() / 2)
                            LocalPlayer():SetNWBool("IntroActive", false)
                            RunConsoleCommand("dsp_volume", "1")
                  
                  			if (IsValid(AmalgamInfoMenu)) then
                      			AmalgamInfoMenu:Close()
                     		end
                    	
                    		AmalgamInfoMenu = vgui.Create("AmalgamInfoMenu")
                        end
                    end)
                else
                    typedText = ""
                    typingIndex = 0
                    isTyping = true
                    isDeleting = false
                    nextCharTime = CurTime() + typingSpeed
                end
            end
        end
    end)
end

hook.Add("PlayerBindPress", "BlockAllInputsDuringIntro", function(_, bind)
    if (introStarted and not canSpawn) then
        return true
    end
end)

hook.Add("CreateMove", "BlockMovementDuringIntro", function(cmd)
    if (introStarted and not canSpawn) then
        cmd:SetForwardMove(0)
        cmd:SetSideMove(0)
        cmd:SetUpMove(0)
        cmd:ClearButtons()
    end
end)

net.Receive("nStartIntro", function()
    Amalgam:RunIntroSequence()
end)

concommand.Add("start_intro", function()
    Amalgam:RunIntroSequence()
end)
