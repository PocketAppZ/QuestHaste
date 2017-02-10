QuestHaste_EventHandler = CreateFrame("FRAME")
QuestHaste_EventHandler:RegisterEvent("ADDON_LOADED")

function QuestHaste_RegisterEvents()
    QuestHaste_EventHandler:RegisterEvent("QUEST_PROGRESS")
    QuestHaste_EventHandler:RegisterEvent("QUEST_COMPLETE")
    QuestHaste_EventHandler:RegisterEvent("QUEST_DETAIL")
    QuestHaste_EventHandler:RegisterEvent("GOSSIP_SHOW")
end

function QuestHaste_UnregisterEvents()
    QuestHaste_EventHandler:UnregisterEvent("QUEST_PROGRESS")
    QuestHaste_EventHandler:UnregisterEvent("QUEST_COMPLETE")
    QuestHaste_EventHandler:UnregisterEvent("QUEST_DETAIL")
    QuestHaste_EventHandler:UnregisterEvent("GOSSIP_SHOW")
end

local function filterEvens(t)
    local r = {}
    for k,v in t do
        if math.mod(k,2) ~= 0 then
            r[(k+1)/2] = v
        end
    end
    return r
end

local function contained(t,val)
    for _,v in t do
        if v == val then
            return true
        end
    end
    return false
end

function QuestHaste_EventHandler.GOSSIP_SHOW()
    local function SetupBackground(b)
        b:SetAllPoints(b:GetParent()) b:SetDrawLayer("BACKGROUND",-1) b:SetTexture(1,1,1) b:SetGradientAlpha("HORIZONTAL", 0.5, 1, 0, 0.5, 1, 1, 0, 0)
    end
    local available = filterEvens({GetGossipAvailableQuests()})
    local active = filterEvens({GetGossipActiveQuests()})

    for i = 1,32 do
        local f = getglobal("GossipTitleButton"..i)
        
        if f.QHaste == nil then
            f.QHaste = {background = f:CreateTexture(), oldScript = f:GetScript("OnClick")}
            SetupBackground(f.QHaste.background)
            local function OnClick(...)
                if IsAltKeyDown() and QuestHaste.autolist[f:GetText()] then
                    if contained(available, f:GetText()) then
                        QuestHaste_RemoveAutoAccept(f:GetText())
                    else
                        QuestHaste_RemoveAutoComplete(f:GetText())
                    end
                    f.QHaste.background:Hide()
                else
                    f.QHaste.oldScript(unpack(arg))
                end
            end
            f:SetScript("OnClick",OnClick)
        end
        if QuestHaste.autolist[f:GetText()]
        then f.QHaste.background:Show()
        else f.QHaste.background:Hide()
        end
    end
    if IsShiftKeyDown() then
        for k,v in filterEvens({GetGossipActiveQuests()}) do
            if contained(active, v) and QuestHaste_IsAutoComplete(v) then
                SelectGossipActiveQuest(k)
                return
            end
        end
    end
    if IsControlKeyDown() then
        for k,v in filterEvens({GetGossipAvailableQuests()}) do
            if contained(available, v) and QuestHaste_IsAutoAccept(v) then
                SelectGossipAvailableQuest(k)
                return
            end
        end
    end
end

function QuestHaste_EventHandler.QUEST_PROGRESS()
    local title = GetTitleText()
    
    if IsShiftKeyDown() then QuestHaste_AddAutoComplete(title)
    elseif IsAltKeyDown() then QuestHaste_RemoveAutoComplete(title) return end

    if (QuestHaste.currentQuest == title or QuestHaste_IsAutoComplete(title) ~= (IsControlKeyDown() ~= nil)) and QuestFrameCompleteButton:IsEnabled()==1 then
        CompleteQuest()
    else
        QuestHaste.currentQuest = ""
    end
end

function QuestHaste_EventHandler.QUEST_COMPLETE()
    local title = GetTitleText()
    
    if IsShiftKeyDown() then QuestHaste_AddAutoComplete(title)
    elseif IsAltKeyDown() then QuestHaste_RemoveAutoComplete(title) return end
    
    if (QuestHaste.currentQuest == title or QuestHaste_IsAutoComplete(title) ~= (IsControlKeyDown() ~= nil)) and QuestFrameCompleteQuestButton:IsEnabled()==1 then
        GetQuestReward()
    end
    QuestHaste.currentQuest = ""
end

function QuestHaste_EventHandler.QUEST_DETAIL()
    local title = GetTitleText()
    
    if IsShiftKeyDown() then QuestHaste_AddAutoAccept(title)
    elseif IsAltKeyDown() then QuestHaste_RemoveAutoAccept(title) return end

    if QuestHaste.currentQuest == title or QuestHaste_IsAutoAccept(title) ~= (IsControlKeyDown() ~= nil) then
        AcceptQuest()
    else
        QuestHaste.currentQuest = ""
    end
end

function QuestHaste_EventHandler.ADDON_LOADED()
    if arg1 == "QuestHaste" then
        QuestHaste_Session = {}
        if QuestHaste == nil or QuestHaste.autolist == nil then
            QuestHaste = {autolist = {}, dataVersion = "1.0.0"}
        end
        if QuestHaste.dataVersion == nil then
            local tmp = {}
            for k,_ in QuestHaste.autolist do
                tmp[k] = {complete=true}
            end
            QuestHaste.autolist = tmp
            QuestHaste.dataVersion = "1.0.0"
        end
        QuestHaste_RegisterEvents()
        QuestHaste_EventHandler:UnregisterEvent("ADDON_LOADED")
    end
end

QuestHaste_EventHandler:SetScript("OnEvent",
    function ()
        if QuestHaste_EventHandler[event]
        then QuestHaste_EventHandler[event]()
        end
    end
)

function QuestHaste_IsAutoComplete(title)
    return QuestHaste.autolist[title] and QuestHaste.autolist[title].complete
end

function QuestHaste_IsAutoAccept(title)
    return QuestHaste.autolist[title] and QuestHaste.autolist[title].accept
end

function QuestHaste_AddAutoComplete(title)
    if QuestHaste_IsAutoComplete(title) then return end
    if QuestHaste.autolist[title] == nil then QuestHaste.autolist[title] = {} end
    QuestHaste.autolist[title].complete = true
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cff00ff00added|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_AddAutoAccept(title)
    if QuestHaste_IsAutoAccept(title) then return end
    if QuestHaste.autolist[title] == nil then QuestHaste.autolist[title] = {} end
    QuestHaste.autolist[title].accept = true
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cff00ff00added|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_RemoveAutoComplete(title)
    if not QuestHaste_IsAutoComplete(title) then return end
    if QuestHaste_IsAutoAccept(title) then
        QuestHaste.autolist[title].complete = false
    else 
        QuestHaste.autolist[title] = nil
    end
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cffff0000removed|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_RemoveAutoAccept(title)
    if not QuestHaste_IsAutoAccept(title) then return end
    if QuestHaste_IsComplete(title) then
        QuestHaste.autolist[title].accept = false
    else
        QuestHaste.autolist[title] = nil
    end
    local msg = "|cffffff88QuestHaste|r: |cffffff00"..title.."|r |cffff0000removed|r."
    UIErrorsFrame:AddMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage(msg)
end

function QuestHaste_Proceed()
    if GossipFrame:IsShown() then
        QuestHaste.currentQuest = GetGossipActiveQuests()
        SelectGossipActiveQuest(1)
    elseif QuestFrame:IsShown() then
        local title = GetTitleText()
        if QuestFrameAcceptButton:IsShown() and QuestFrameAcceptButton:IsEnabled()==1 then
            AcceptQuest()
        elseif QuestFrameCompleteButton:IsShown() and QuestFrameCompleteButton:IsEnabled()==1 then
            QuestHaste.currentQuest = title
            CompleteQuest()
        elseif QuestFrameCompleteQuestButton:IsShown() and QuestFrameCompleteQuestButton:IsEnabled()==1 then
            GetQuestReward()
        end
    end
end

local function CommandParser(msg, editbox)
    local _,_,command, rest = string.find(msg,"^(%S*)%s*(.-)$")
    if command == "add" then
        if QuestFrame:IsShown() then
            local title = GetTitleText()
            QuestHaste_AddAutoComplete(title)
        else
            UIErrorsFrame:AddMessage("QuestHaste: no active quest.",1,0,0)
        end
        QuestHaste_Proceed()
    --elseif command == "remove" then
    --    QuestHaste.autolist[title] = nil
    elseif command == "list" then
        DEFAULT_CHAT_FRAME:AddMessage("QuestHaste quest list:")
        for k,_ in QuestHaste.autolist do
            DEFAULT_CHAT_FRAME:AddMessage("    "..k)
        end
    elseif command == "pause" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r: |cffff0000paused|r.")
        QuestHaste_UnregisterEvents()
    elseif command == "resume" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff88QuestHaste|r: |cff00ff00active|r.")
        QuestHaste_RegisterEvents()
    elseif command == "complete" then
        QuestHaste_Proceed()
    elseif command == "reset" then
        QuestHaste.autolist = {}
    else
        DEFAULT_CHAT_FRAME:AddMessage("Syntax: /qhaste add\n/qhaste list\n/qhaste complete\n/qhaste pause\n/qhaste resume\n/qhaste reset");
    end
end
SLASH_QUESTHASTE1 = "/qhaste"
SlashCmdList["QUESTHASTE"] = CommandParser
