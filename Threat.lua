--[[
  Threat
  By: Ollowain.
  Modified for Turtle: allfox.
	Credit: Fury.lua by Bhaerau.
]]--

-- Variables
local RevengeReadyUntil = 0;
local InCombat = false;
local ThreatLastSpellCast = 0
local ChallengingShoutBroadcasted = true;
local ChallengingShoutCountdown = -1;
local ChallengingLastBroadcastTime = 0;

function Threat_Configuration_Init()
  if (not Threat_Configuration) then
    Threat_Configuration = { };
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

function SpellId(spellname)
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

function SpellReady(spellname)
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
function SpellNearlyReady(spellname)
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

function HasBuff(unit, texturename)
  local id = 1;
  while (UnitBuff(unit, id)) do
    local buffTexture = UnitBuff(unit, id);
    if (string.find(buffTexture, texturename)) then
      return true;
    end
    id = id + 1;
  end
  return nil;
end

function ActiveStance()
  for i = 1, 3 do
    local _, _, active = GetShapeshiftFormInfo(i);
    if (active) then
      return i;
    end
  end
  return nil;
end

function HasOneSunderArmor(unit)
  local id = 1;
  while (UnitDebuff(unit, id)) do
    local debuffTexture, debuffAmount = UnitDebuff(unit, id);
    if (string.find(debuffTexture, "Sunder")) then
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

function HasFiveSunderArmors(unit)
  local id = 1;
  while (UnitDebuff(unit, id)) do
    local debuffTexture, debuffAmount = UnitDebuff(unit, id);
    if (string.find(debuffTexture, "Sunder")) then
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

function RevengeAvail()
  if GetTime() < RevengeReadyUntil then
    return true;
  else
    return nil;
  end
end

function ShieldSlamLearned()
  if UnitClass("player") == "Warrior" then
    local _, _, _, _, ss = GetTalentInfo(3,17);
    if (ss >= 1) then
      return true;
    else
      return nil;
    end
  end
end

function BloodthirstLearned()
  if UnitClass("player") == "Warrior" then
    local _, _, _, _, ss = GetTalentInfo(2,17);
    if (ss >= 1) then
      return true;
    else
      return nil;
    end
  end
end

function EquippedShield()
  -- The idea of using tooltip to decide if offhand has a shiled is taken from Roid Macros (https://denniswg.github.io/Roid-Macros/)
  -- Must do this SetOwner in this function, or tooltip would be blank
  ThreatTooltip:SetOwner(UIParent, "ANCHOR_NONE");

  local hasItem, hasCooldown, repairCost = ThreatTooltip:SetInventoryItem("player", GetInventorySlotInfo("SecondaryHandSlot"));
  if not hasItem then
    return nil;
  end

  local lineCount = ThreatTooltip:NumLines();
  for i = 1, lineCount do
    local leftText = getglobal("ThreatTooltipTextLeft"..i);
    local itemType = getglobal("ThreatTooltipTextRight"..i);

    -- Some item has attribute "Unique" which would append 1 line in front of the type line
    -- Check on left attribute to make sure we are looking into the type line
    if(leftText:GetText() and 
        (leftText:GetText() == ITEM_ATTRIBUTE_OFFHAND_THREAT or
         leftText:GetText() == ITEM_ATTRIBUTE_MAINHAND_THREAT or
         leftText:GetText() == ITEM_ATTRIBUTE_ONEHAND_THREAT or
         leftText:GetText() == ITEM_ATTRIBUTE_TWOHAND_THREAT
        )
      ) then
      
      if(itemType:GetText() and itemType:GetText() == ITEM_TYPE_SHIELD_THREAT) then
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
  if (not UnitIsCivilian("target") and UnitClass("player") == CLASS_WARRIOR_THREAT) then

    local rage = UnitMana("player");
    local hp = UnitHealth("player");
    local maxhp = UnitHealthMax("player");

    if (not ThreatAttack) then
      Debug("Starting AutoAttack");
      AttackTarget();
    end

--[[
    if not IsCurrentAction(22) then
      Debug("Starting AutoAttack");
      UseAction(22);
    end
]]

    if (ActiveStance() ~= 2) then
      Debug("Changing to def stance");
      CastSpellByName(ABILITY_DEFENSIVE_STANCE_THREAT);
    end

    if (InCombat) then
      --[[
      if (SpellReady(ABILITY_BLOODRAGE_THREAT)) then
        Debug("Bloodrage");
        CastSpellByName(ABILITY_BLOODRAGE_THREAT);
      ]]
      if (SpellReady(ABILITY_REVENGE_THREAT) and RevengeAvail() and rage >= 5) then
        Debug("Revenge");
        CastSpellByName(ABILITY_REVENGE_THREAT);
      elseif (rage >= 10 and (hp / maxhp * 100) < 40 and EquippedShield() and SpellReady(ABILITY_SHIELD_BLOCK_THREAT)) then
        Debug("Sheld Block when HP < 40");
        CastSpellByName(ABILITY_SHIELD_BLOCK_THREAT);
      elseif (SpellReady(ABILITY_SUNDER_ARMOR_THREAT) and rage >= 15 and not HasOneSunderArmor("target")) then
        Debug("First Sunder armor");
        CastSpellByName(ABILITY_SUNDER_ARMOR_THREAT);
      elseif (SpellReady(ABILITY_SHIELD_SLAM_THREAT) and rage >= 20 and ShieldSlamLearned()) then
        Debug("Shield slam");
        CastSpellByName(ABILITY_SHIELD_SLAM_THREAT);
      elseif (SpellReady(ABILITY_BATTLE_SHOUT_THREAT) and not HasBuff("player", "Ability_Warrior_BattleShout") and rage >= 10) then
        Debug("Battle Shout");
        CastSpellByName(ABILITY_BATTLE_SHOUT_THREAT);
      elseif (SpellReady(ABILITY_BLOODTHIRST_THREAT) and rage >= 30 and BloodthirstLearned()) then
        Debug("Bloodthirst");
        CastSpellByName(ABILITY_BLOODTHIRST_THREAT);
      elseif (((BloodthirstLearned() and not SpellNearlyReady(ABILITY_BLOODTHIRST_THREAT)) or 
                (ShieldSlamLearned() and not SpellNearlyReady(ABILITY_SHIELD_SLAM_THREAT)) or 
                (not BloodthirstLearned() and not ShieldSlamLearned())) and 
              UnitIsUnit("targettarget", "player") and 
              SpellReady(ABILITY_SHIELD_BLOCK_THREAT) and 
              EquippedShield() and rage >= 15 and 
              (hp < maxhp)) then
        Debug("Sheld Block normally");
        CastSpellByName(ABILITY_SHIELD_BLOCK_THREAT);
      elseif (((BloodthirstLearned() and not SpellNearlyReady(ABILITY_BLOODTHIRST_THREAT)) or 
                (ShieldSlamLearned() and not SpellNearlyReady(ABILITY_SHIELD_SLAM_THREAT)) or 
                (ShieldSlamLearned() and not EquippedShield()) or 
                (not BloodthirstLearned() and not ShieldSlamLearned())) and 
              SpellReady(ABILITY_SUNDER_ARMOR_THREAT) and 
              rage >= 15 and 
              not HasFiveSunderArmors("target")) then
        Debug("Sunder Armor");
        CastSpellByName(ABILITY_SUNDER_ARMOR_THREAT);
      elseif (SpellReady(ABILITY_HEROIC_STRIKE_THREAT) and rage >= 45) then
        Debug("Heroic strike");
        CastSpellByName(ABILITY_HEROIC_STRIKE_THREAT);
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
  this:RegisterEvent("VARIABLES_LOADED");
  this:RegisterEvent("PLAYER_ENTER_COMBAT");
  this:RegisterEvent("PLAYER_LEAVE_COMBAT");
  this:RegisterEvent("PLAYER_REGEN_DISABLED");
  this:RegisterEvent("PLAYER_REGEN_ENABLED");
  this:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES");
  this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE");

  ThreatLastSpellCast = GetTime();
  ChallengingShoutBroadcasted = not SpellReady(ABILITY_CHALLENGING_SHOUT_THREAT);

  SlashCmdList["WARRTHREAT"] = Threat_SlashCommand;
  SLASH_WARRTHREAT1 = "/warrthreat";
end

function Threat_OnEvent(event)
  if (event == "VARIABLES_LOADED") then
    Threat_Configuration_Init()
  elseif (event == "PLAYER_ENTER_COMBAT") then
    ThreatAttack = true;
  elseif (event == "PLAYER_LEAVE_COMBAT") then
    ThreatAttack = nil;
  elseif (event == "PLAYER_REGEN_DISABLED") then
    InCombat = true;
  elseif (event == "PLAYER_REGEN_ENABLED") then
    InCombat = false;
  elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE") then
    -- These resist check is taken from TankBuddy (https://github.com/srazdokunebil/TankBuddy/blob/main/TankBuddy.lua)
    if (string.find(arg1, EVENT_CHECK_TAUNT_RESIST_THREAT)) then
      SendChatMessage("Taunt RESISTED");
    elseif (string.find(arg1, EVENT_FIRE_MOCKING_BLOW_THREAT)) then
      if (not string.find(arg1, EVENT_HIT_MOCKING_BLOW_THREAT)) then
        SendChatMessage("Mocking Blow MISSED");
      end
    end
  elseif (event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")then
    if string.find(arg1,"You block")
    or string.find(arg1,"You parry")
    or string.find(arg1,"You dodge") then
      Debug("Revenge soon ready");
      RevengeReadyUntil = GetTime() + 4;
    end
  end
end



function Threat_OnUpdate()
  if (ChallengingShoutBroadcasted and SpellNearlyReady(ABILITY_CHALLENGING_SHOUT_THREAT)) then
    ChallengingShoutBroadcasted = false;
  elseif (not ChallengingShoutBroadcasted and not SpellNearlyReady(ABILITY_CHALLENGING_SHOUT_THREAT)) then
    ChallengingShoutBroadcasted = true;

    -- While Challenging Shout lasts 6 sec, the last sec message would show up as "1 sec left" if we count as 6,5,4,3,2,1, and keep displaying even that last sec has passed
    -- Better let last sec show up as "0 sec left", so peeps get warned taunt is over
    ChallengingShoutCountdown = 5;
  end

  if (ChallengingShoutCountdown >= 0 and (GetTime() - ChallengingLastBroadcastTime >= 1)) then
    SendChatMessage(ChallengingShoutCountdown.."  Challenging Shout ends in "..ChallengingShoutCountdown.." sec");
    ChallengingLastBroadcastTime = GetTime();
    ChallengingShoutCountdown = ChallengingShoutCountdown - 1;
  end
end
