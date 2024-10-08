--[[
  Threat
  Origin By: Ollowain.
  Modified for Turtle: allfox.
	Credit: Fury.lua by Bhaerau.
]] --
-- Variables
local RevengeReadyUntil = 0;
local ThreatLastSpellCast = 0
local ChallengingShoutBroadcasted = true;
local ChallengingShoutCountdown = -1;
local ChallengingLastBroadcastTime = 0;
local LastSunderArmorTime = 0;
local LastBattleShoutAttemptTime = 0;
local LastDisarmAttemptTime = 0;
local LastHeroicStrikeTime = 0;
local LastOnUpdateTime = 0;
local ShieldWallBroadcasted = true;
local ShieldWallEnding = -1;
local LastStandBroadcasted = true;
local LastStandEnding = -1;
local GainHP = 0;

-- Would be SavedVariables, not local
Threat_KnownDisarmImmuneTable = nil;

function Threat_Configuration_Init()
    if (not Threat_Configuration) then
        Threat_Configuration = {};
    end

    if (Threat_Configuration["Debug"] == nil) then
        Threat_Configuration["Debug"] = false;
    end
end

-- Normal Functions

local function Print(msg)
    if (not DEFAULT_CHAT_FRAME) then
        return;
    end
    DEFAULT_CHAT_FRAME:AddMessage(msg);
end

local function Debug(msg)
    if (Threat_Configuration["Debug"]) then
        if (not DEFAULT_CHAT_FRAME) then
            return;
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg);
    end
end

--------------------------------------------------

local function SpellId(spellname)
    local id = 1;
    for i = 1, GetNumSpellTabs() do
        local _, _, _, numSpells = GetSpellTabInfo(i);
        for j = 1, numSpells do
            local spellName = GetSpellName(id, BOOKTYPE_SPELL);
            if (spellName == spellname) then
                return id;
            end
            id = id + 1;
        end
    end
    return nil;
end

local function SpellReady(spellname)
    local id = SpellId(spellname);
    if (id) then
        local start, duration = GetSpellCooldown(id, 0);
        if (start == 0 and duration == 0 and ThreatLastSpellCast + 1 <= GetTime()) then
            return true;
        end
    end
    return nil;
end

-- This function consider GCD still be ready state
local function SpellNearlyReady(spellname)
    local id = SpellId(spellname);
    if (id) then
        local start, duration = GetSpellCooldown(id, 0);
        if (start == 0 and duration == 0 and ThreatLastSpellCast + 1 <= GetTime()) then
            return true;
        end
        if (start >= 0 and duration <= 1.6 and ThreatLastSpellCast + 1 <= GetTime()) then
            return true;
        end
    end
    return nil;
end

local function HasBuff(unit, texturename)
    texturename = string.lower(texturename);
    local id = 1;

    while (UnitBuff(unit, id)) do
        local buffTexture = string.lower(UnitBuff(unit, id));
        if (string.find(buffTexture, texturename)) then
            return true;
        end
        id = id + 1;
    end
    return nil;
end

local function ActiveStance()
    for i = 1, 3 do
        local _, _, active = GetShapeshiftFormInfo(i);
        if (active) then
            return i;
        end
    end
    return nil;
end

local function HasDisarm(unit)
    local id = 1;
    while (UnitDebuff(unit, id)) do
        local debuffTexture, debuffAmount = UnitDebuff(unit, id);
        if (string.find(debuffTexture, DEBUFF_DISARM_THREAT)) then
            if (debuffAmount >= 1) then
                return true;
            else
                return nil;
            end
        end
        id = id + 1;
    end
    return nil;
end

local function isKnownImmuneToDisarm(mobName)
    for i, v in pairs(Threat_KnownDisarmImmuneTable) do
        if (mobName == v) then
            return true;
        end
    end

    return false;
end

local function HasOneSunderArmor(unit)
    local id = 1;
    while (UnitDebuff(unit, id)) do
        local debuffTexture, debuffAmount = UnitDebuff(unit, id);
        if (string.find(debuffTexture, DEBUFF_SUNDER_ARMOR_THREAT)) then
            if (debuffAmount >= 1) then
                return true;
            else
                return nil;
            end
        end
        id = id + 1;
    end
    return nil;
end

local function HasFiveSunderArmors(unit)
    local id = 1;
    while (UnitDebuff(unit, id)) do
        local debuffTexture, debuffAmount = UnitDebuff(unit, id);
        if (string.find(debuffTexture, DEBUFF_SUNDER_ARMOR_THREAT)) then
            if (debuffAmount >= 5) then
                return true;
            else
                return nil;
            end
        end
        id = id + 1;
    end
    return nil;
end

local function RevengeAvail()
    if GetTime() < RevengeReadyUntil then
        return true;
    else
        return nil;
    end
end

local function ShieldSlamLearned()
    if UnitClass("player") == CLASS_WARRIOR_THREAT then
        local _, _, _, _, ss = GetTalentInfo(3, 17);
        if (ss >= 1) then
            return true;
        else
            return nil;
        end
    end
end

local function BloodthirstLearned()
    if UnitClass("player") == CLASS_WARRIOR_THREAT then
        local _, _, _, _, ss = GetTalentInfo(2, 17);
        if (ss >= 1) then
            return true;
        else
            return nil;
        end
    end
end

-- return how many time increasement of Improved Shield Wall talent has been learnt
local function ImprovedSheildWallIncrasedTime()
    if UnitClass("player") == CLASS_WARRIOR_THREAT then
        local _, _, _, _, ss = GetTalentInfo(3, 13);
        if (ss == 1) then
            return 3;
        elseif (ss == 2) then
            return 5;
        else
            return 0;
        end
    end
end

-- read rage cost from spell book. it would show reduction from talent
local function RageCost(spellName)
    -- Must do this SetOwner in this function, or tooltip would be blank
    ThreatTooltip:SetOwner(UIParent, "ANCHOR_NONE");

    local spellID = SpellId(spellName);
    if not spellID then
        -- if we can't find this spell in book, we return a huge cost so we won't use it
        Debug("Can't find " .. spellName .. " in book");
        return 9999;
    end

    ThreatTooltip:SetSpell(spellID, BOOKTYPE_SPELL);

    local lineCount = ThreatTooltip:NumLines();

    for i = 1, lineCount do
        local leftText = getglobal("ThreatTooltipTextLeft" .. i);

        if leftText:GetText() then
            local _, _, rage = string.find(leftText:GetText(), RAGE_DESCRIPTION_REGEX_THREAT);

            if rage then
                return tonumber(rage);
            end
        end
    end

    -- Spells like taunt doesn't cost rage, they dont have rage cost in description
    return 0;
end

local function EquippedShield()
    -- The idea of using tooltip to decide if offhand has a shiled is taken from Roid Macros (https://denniswg.github.io/Roid-Macros/)
    -- Must do this SetOwner in this function, or tooltip would be blank
    ThreatTooltip:SetOwner(UIParent, "ANCHOR_NONE");

    local hasItem, hasCooldown, repairCost = ThreatTooltip:SetInventoryItem("player",
        GetInventorySlotInfo("SecondaryHandSlot"));
    if not hasItem then
        return nil;
    end

    local lineCount = ThreatTooltip:NumLines();
    for i = 1, lineCount do
        local leftText = getglobal("ThreatTooltipTextLeft" .. i);
        local itemType = getglobal("ThreatTooltipTextRight" .. i);

        -- Some item has attribute "Unique" which would append 1 line in front of the type line
        -- Check on left attribute to make sure we are looking into the type line
        if (leftText:GetText() and
            (leftText:GetText() == ITEM_ATTRIBUTE_OFFHAND_THREAT or leftText:GetText() == ITEM_ATTRIBUTE_MAINHAND_THREAT or
                leftText:GetText() == ITEM_ATTRIBUTE_ONEHAND_THREAT or leftText:GetText() ==
                ITEM_ATTRIBUTE_TWOHAND_THREAT)) then
            if (itemType:GetText() and itemType:GetText() == ITEM_TYPE_SHIELD_THREAT) then
                return true;
            else
                -- Some item would bug on labels, showing past info instead of current.
                -- However, It looks the very first info would be OK.
                return false;
            end
        end
    end

    return false;
end

function Threat()

    -- addon is not yet fully loaded
    if (not Threat_KnownDisarmImmuneTable) then
        return;
    end

    if (not UnitIsCivilian("target") and UnitClass("player") == CLASS_WARRIOR_THREAT) then
        local rage = UnitMana("player");
        local hp = UnitHealth("player");
        local maxhp = UnitHealthMax("player");
        local attackSpeed = UnitAttackSpeed("player");
        local i,j,k;

        -- According to https://wowwiki-archive.fandom.com/wiki/ActionSlot
        -- We have 120 Action Slots
        for i=1,120 do
            if IsAttackAction(i) and not IsCurrentAction(i) then
                UseAction(i);
            end
        end


        if (ActiveStance() ~= 2) then
            Debug("Changing to def stance");
            CastSpellByName(ABILITY_DEFENSIVE_STANCE_THREAT);
        end

        local InCombat = UnitAffectingCombat("player");

        if (InCombat) then
            --[[
      if (SpellReady(ABILITY_BLOODRAGE_THREAT)) then
        Debug("Bloodrage");
        CastSpellByName(ABILITY_BLOODRAGE_THREAT);
      ]]
            local revengeCost = RageCost(ABILITY_REVENGE_THREAT);
            local blockCost = RageCost(ABILITY_SHIELD_BLOCK_THREAT);
            local sunderCost = RageCost(ABILITY_SUNDER_ARMOR_THREAT);
            local apCost = RageCost(ABILITY_BATTLE_SHOUT_THREAT);
            local disarmCost = RageCost(ABILITY_DISARM_THREAT);
            local hsCost = RageCost(ABILITY_HEROIC_STRIKE_THREAT);
            local coreCost = (function()
                if BloodthirstLearned() then
                    return RageCost(ABILITY_BLOODTHIRST_THREAT);
                end

                if ShieldSlamLearned() then
                    return RageCost(ABILITY_SHIELD_SLAM_THREAT);
                end

                return 0;
            end)();

            if (SpellReady(ABILITY_HEROIC_STRIKE_THREAT) and rage >= (coreCost + sunderCost + revengeCost + hsCost) and
                (GetTime() - LastHeroicStrikeTime > attackSpeed / 2)) then
                --[[
                    The idea of adding Heroic Strike a cooldown is from Fury (https://github.com/cubenicke/Fury/blob/master/Fury.lua)
                    As weapon attack speed is the limiter to heroic strike, HS in fact can not fire continuously.
                    However if there is no cooldown, HS would block other spell until it's fired.

                    Also HS should in top position. Because it is possible we need rage dump even before mob got 5 sunder.
                ]]
                Debug("Heroic strike");
                LastHeroicStrikeTime = GetTime();
                CastSpellByName(ABILITY_HEROIC_STRIKE_THREAT);
            elseif (SpellReady(ABILITY_REVENGE_THREAT) and RevengeAvail() and rage >= revengeCost) then
                Debug("Revenge");
                CastSpellByName(ABILITY_REVENGE_THREAT);
            elseif (rage >= blockCost and (hp / maxhp * 100) < 40 and EquippedShield() and
                SpellReady(ABILITY_SHIELD_BLOCK_THREAT)) then
                Debug("Sheld Block when HP < 40");
                CastSpellByName(ABILITY_SHIELD_BLOCK_THREAT);
            elseif (SpellReady(ABILITY_SUNDER_ARMOR_THREAT) and rage >= sunderCost and
                (not HasOneSunderArmor("target") or LastSunderArmorTime + 25 <= GetTime())) then
                Debug("First/Refresh Sunder armor");
                LastSunderArmorTime = GetTime();
                CastSpellByName(ABILITY_SUNDER_ARMOR_THREAT);
            elseif (SpellReady(ABILITY_BATTLE_SHOUT_THREAT) and not HasBuff("player", "Ability_Warrior_BattleShout") and
                rage >= (apCost + sunderCost) and (GetTime() - LastBattleShoutAttemptTime > 3)) then
                Debug("Battle Shout");
                LastBattleShoutAttemptTime = GetTime();
                CastSpellByName(ABILITY_BATTLE_SHOUT_THREAT);
            elseif (not HasDisarm("target") and SpellReady(ABILITY_DISARM_THREAT) and rage >= (disarmCost + sunderCost) and
                (GetTime() - LastDisarmAttemptTime > 3) and
                (string.find(UnitClassification("target"), CLASSIFICATION_ELITE_THREAT) or
                    string.find(UnitClassification("target"), CLASSIFICATION_WORLDBOSS_THREAT)) and
                not isKnownImmuneToDisarm(UnitName("target"))) then
                Debug("Disarm");
                LastDisarmAttemptTime = GetTime();
                CastSpellByName(ABILITY_DISARM_THREAT);
            elseif (UnitIsUnit("targettarget", "player") and SpellReady(ABILITY_SHIELD_BLOCK_THREAT) and
                EquippedShield() and rage >= (blockCost + sunderCost) and (hp / maxhp * 100) < 85) then
                Debug("Sheld Block normally");
                CastSpellByName(ABILITY_SHIELD_BLOCK_THREAT);
            elseif (SpellReady(ABILITY_SUNDER_ARMOR_THREAT) and rage >= (sunderCost + revengeCost) and
                not HasFiveSunderArmors("target")) then
                Debug("Sunder Armor");
                CastSpellByName(ABILITY_SUNDER_ARMOR_THREAT);
                LastSunderArmorTime = GetTime();
            elseif (SpellReady(ABILITY_SHIELD_SLAM_THREAT) and rage >= (coreCost + sunderCost) and ShieldSlamLearned()) then
                Debug("Shield slam");
                CastSpellByName(ABILITY_SHIELD_SLAM_THREAT);
            elseif (SpellReady(ABILITY_BLOODTHIRST_THREAT) and rage >= (coreCost + sunderCost) and BloodthirstLearned()) then
                Debug("Bloodthirst");
                CastSpellByName(ABILITY_BLOODTHIRST_THREAT);
            end
        end
    end
end

-- Chat Handlers

function Threat_SlashCommand(msg)
    local _, _, command, options = string.find(msg, "([%w%p]+)%s*(.*)$");
    if (command) then
        command = string.lower(command);
    end
    if (command == nil or command == "") then
        Threat();
    elseif (command == "debug") then
        if (Threat_Configuration["Debug"]) then
            Threat_Configuration["Debug"] = false;
            Print(BINDING_HEADER_THREAT .. ": " .. SLASH_THREAT_DEBUG .. " " .. SLASH_THREAT_DISABLED .. ".")
        else
            Threat_Configuration["Debug"] = true;
            Print(BINDING_HEADER_THREAT .. ": " .. SLASH_THREAT_DEBUG .. " " .. SLASH_THREAT_ENABLED .. ".")
        end
    else
        Print(SLASH_THREAT_HELP)
    end
end

-- Event Handlers

function Threat_OnLoad()
    this:RegisterEvent("ADDON_LOADED");
    this:RegisterEvent("PLAYER_ENTER_COMBAT");
    this:RegisterEvent("PLAYER_LEAVE_COMBAT");
    this:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES");
    this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE");

    SlashCmdList["WARRTHREAT"] = Threat_SlashCommand;
    SLASH_WARRTHREAT1 = "/warrthreat";
end

function Threat_OnEvent(event)
    if (event == "ADDON_LOADED" and arg1 == "Threat") then
        Threat_Configuration_Init();

        if (Threat_KnownDisarmImmuneTable == nil) then
            Threat_KnownDisarmImmuneTable = {};
        end

        ThreatLastSpellCast = GetTime();
        ChallengingShoutBroadcasted = not SpellReady(ABILITY_CHALLENGING_SHOUT_THREAT);
        LastStandBroadcasted = not SpellReady(ABILITY_LAST_STAND_THREAT);
        ShieldWallBroadcasted = not SpellReady(ABILITY_SHIELD_WALL_THREAT);

        Print(
            "Threat loaded. Make a macro to call \124cFFC69B6D/warrthreat\124r command to perform tanking rotation as lv60 Warrior.");
    elseif (event == "PLAYER_ENTER_COMBAT") then
        ThreatAttack = true;
    elseif (event == "PLAYER_LEAVE_COMBAT") then
        ThreatAttack = nil;
    elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE") then
        if (string.find(arg1, EVENT_CHECK_DISARM_FAILED_THREAT)) then
            local _, _, mobName = string.find(arg1, EVENT_CHECK_DISARM_FAILED_THREAT);

            if (mobName and not isKnownImmuneToDisarm(mobName)) then
                table.insert(Threat_KnownDisarmImmuneTable, mobName);
            end
        end

        -- These resist check is taken from TankBuddy (https://github.com/srazdokunebil/TankBuddy/blob/main/TankBuddy.lua)
        if (string.find(arg1, EVENT_CHECK_TAUNT_RESIST_THREAT)) then
            local _, _, mobName = string.find(arg1, EVENT_CHECK_TAUNT_RESIST_THREAT);

            if (not mobName) then
                mobName = "";
            end

            local tauntMessage = string.gsub(MESSAGE_TAUNT_RESIST_THREAT, "$mob_name", mobName);
            SendChatMessage(tauntMessage);

        elseif (string.find(arg1, EVENT_FIRE_MOCKING_BLOW_THREAT)) then
            if (not string.find(arg1, EVENT_HIT_MOCKING_BLOW_THREAT)) then
                local _, _, reason, mobName = string.find(arg1, EVENT_FAILED_MOCKING_BLOW_THREAT);

                if (reason) then
                    reason = string.upper(reason) .. " " .. MESSAGE_BY_THREAT;
                else
                    reason = MESSAGE_MISSED_THREAT;
                end

                if (not mobName) then
                    local _, _, mobName2 = string.find(arg1, EVENT_MISSED_MOCKING_BLOW_THREAT);

                    -- Because the local keyword limits scope, while _ and mobName in different scope
                    mobName = mobName2;

                    if (not mobName) then
                        mobName = "";
                    end
                end

                local mockingBlowMessage = string.gsub(MESSAGE_MOCKING_BLOW_FAILED_THREAT, "$reason", reason);
                mockingBlowMessage = string.gsub(mockingBlowMessage, "$mob_name", mobName);
                SendChatMessage(mockingBlowMessage);

            end
        end
    elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES") then
        if string.find(arg1, EVENT_SELF_BLOCK_THREAT) or string.find(arg1, EVENT_SELF_PARRY_THREAT) or
            string.find(arg1, EVENT_SELF_DOGUE_THREAT) then
            Debug("Revenge soon ready");
            RevengeReadyUntil = GetTime() + 4;
        end
    end
end

function Threat_OnUpdate()
    -- Addon is not yet fully loaded
    if (not Threat_KnownDisarmImmuneTable) then
        return;
    end

    -- Limit frequency to 25Hz. Slow computer might need it
    if (GetTime() < LastOnUpdateTime + (1 / 25)) then
        return;
    else
        LastOnUpdateTime = GetTime();
    end

    if (ChallengingShoutBroadcasted and SpellNearlyReady(ABILITY_CHALLENGING_SHOUT_THREAT)) then
        ChallengingShoutBroadcasted = false;
    elseif (not ChallengingShoutBroadcasted and not SpellNearlyReady(ABILITY_CHALLENGING_SHOUT_THREAT)) then
        ChallengingShoutBroadcasted = true;

        -- While Challenging Shout lasts 6 sec, the last sec message would show up as "1 sec left" if we count as 6,5,4,3,2,1, and keep displaying even that last sec has passed
        -- Better let last sec show up as "0 sec left", so peeps get warned taunt is over
        ChallengingShoutCountdown = 5;
    end

    if (ChallengingShoutCountdown >= 0 and (GetTime() - ChallengingLastBroadcastTime >= 1)) then
        SendChatMessage(ChallengingShoutCountdown .. MESSAGE_CHALLENGING_SHOUT_THREAT .. ChallengingShoutCountdown);
        ChallengingLastBroadcastTime = GetTime();
        ChallengingShoutCountdown = ChallengingShoutCountdown - 1;
    end

    -- Doing both cooldown and buff icon check
    -- Cooldown alone is not enough as Shield Wall share cooldown with Recklessness and Retaliation
    if (ShieldWallBroadcasted and
        (SpellNearlyReady(ABILITY_SHIELD_WALL_THREAT) and not HasBuff("player", "Ability_Warrior_ShieldWall"))) then
        ShieldWallBroadcasted = false;
    elseif (not ShieldWallBroadcasted and
        (not SpellNearlyReady(ABILITY_SHIELD_WALL_THREAT) and HasBuff("player", "Ability_Warrior_ShieldWall"))) then
        ShieldWallBroadcasted = true;
        SendChatMessage(MESSAGE_SHIELD_WALL_THREAT);

        -- Ending announcement would be 3 sec earlier
        ShieldWallEnding = GetTime() + 10 + ImprovedSheildWallIncrasedTime() - 3;
    end

    if (ShieldWallEnding > 0 and (GetTime() >= ShieldWallEnding)) then
        ShieldWallEnding = -1;
        SendChatMessage(MESSAGE_SHIELD_WALL_ENDING_THREAT);
    end

    -- There is a small latency between Last Stand entering cooldown and gaining HP. UnitHealthMax() could return 100% HP even in cooldown
    -- So we also also check against buff icon here
    if (LastStandBroadcasted and
        (SpellNearlyReady(ABILITY_LAST_STAND_THREAT) and not HasBuff("player", "Spell_holy_ashestoashes"))) then
        LastStandBroadcasted = false;
    elseif (not LastStandBroadcasted and
        (not SpellNearlyReady(ABILITY_LAST_STAND_THREAT) and HasBuff("player", "Spell_holy_ashestoashes"))) then
        -- GainHP variable is in closure so scope would be bigger for later ending announcement
        -- At this very moment, UnitHealthMax() is called AFTER Last Stand activated, so it would be including the addtional 30% HP
        -- The formula should calculate against 130% HP (Thanks to Zaggy2 notice this https://forum.turtle-wow.org/viewtopic.php?p=93670#p93657)
        -- Using TankBuddy formula
        GainHP = math.floor(UnitHealthMax("player") / 130 * 30);
        local lastStandMessage = string.gsub(MESSAGE_LAST_STAND_THREAT, "$gain_hp", tostring(GainHP));

        LastStandBroadcasted = true;
        SendChatMessage(lastStandMessage);

        -- Ending announcement would be 3 sec earlier
        LastStandEnding = GetTime() + 20 - 3;
    end

    if (LastStandEnding > 0 and (GetTime() >= LastStandEnding)) then
        local lastStandEndingMessage = string.gsub(MESSAGE_LAST_STAND_ENDING_THREAT, "$gain_hp", tostring(GainHP));

        LastStandEnding = -1;
        SendChatMessage(lastStandEndingMessage);
    end
end
