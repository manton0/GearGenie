-- GearGenie Weight Profiles
-- Stat weights per class/spec, ported from AutoGear

---------------------------------------------------------------------------
-- Mapping: weight key -> ITEM_MOD_*_SHORT globals
-- When a profile says Crit = 1.98, all these globals get weight 1.98
---------------------------------------------------------------------------
GearGenieStatKeyMap = {
   Strength         = { ITEM_MOD_STRENGTH_SHORT },
   Agility          = { ITEM_MOD_AGILITY_SHORT },
   Stamina          = { ITEM_MOD_STAMINA_SHORT },
   Intellect        = { ITEM_MOD_INTELLECT_SHORT },
   Spirit           = { ITEM_MOD_SPIRIT_SHORT },
   Dodge            = { ITEM_MOD_DODGE_RATING_SHORT },
   Parry            = { ITEM_MOD_PARRY_RATING_SHORT },
   Block            = { ITEM_MOD_BLOCK_RATING_SHORT, ITEM_MOD_BLOCK_VALUE_SHORT },
   Defense          = { ITEM_MOD_DEFENSE_SKILL_RATING_SHORT },
   AttackPower      = { ITEM_MOD_ATTACK_POWER_SHORT, ITEM_MOD_RANGED_ATTACK_POWER_SHORT, ITEM_MOD_FERAL_ATTACK_POWER_SHORT },
   Crit             = { ITEM_MOD_CRIT_RATING_SHORT, ITEM_MOD_CRIT_MELEE_RATING_SHORT, ITEM_MOD_CRIT_RANGED_RATING_SHORT },
   SpellCrit        = { ITEM_MOD_CRIT_SPELL_RATING_SHORT },
   Hit              = { ITEM_MOD_HIT_RATING_SHORT, ITEM_MOD_HIT_MELEE_RATING_SHORT, ITEM_MOD_HIT_RANGED_RATING_SHORT },
   SpellHit         = { ITEM_MOD_HIT_SPELL_RATING_SHORT },
   Haste            = { ITEM_MOD_HASTE_RATING_SHORT, ITEM_MOD_HASTE_MELEE_RATING_SHORT, ITEM_MOD_HASTE_RANGED_RATING_SHORT },
   Expertise        = { ITEM_MOD_EXPERTISE_RATING_SHORT },
   SpellPower       = { ITEM_MOD_SPELL_POWER_SHORT, ITEM_MOD_SPELL_DAMAGE_DONE_SHORT, ITEM_MOD_SPELL_HEALING_DONE_SHORT },
   SpellPenetration = { ITEM_MOD_SPELL_PENETRATION_SHORT },
   Mp5              = { ITEM_MOD_MANA_REGENERATION_SHORT, ITEM_MOD_POWER_REGEN0_SHORT },
}

-- Custom stat patterns (DPS and Armor use regex, not ITEM_MOD globals)
GearGenieCustomStatPatterns = {
   DPS   = { Name = "DPS",   Match = "%((%d+[.,]%d+) " .. string.lower(DAMAGE_PER_SECOND) .. "%)" },
   Armor = { Name = "Armor", Match = "(%d+) " .. RESISTANCE0_NAME },
}

---------------------------------------------------------------------------
-- Class display names (token -> friendly name)
---------------------------------------------------------------------------
GearGenieClassNames = {
   ASCENSION   = "Ascension (Hero)",
   DEATHKNIGHT = "Death Knight",
   DEMONHUNTER = "Demon Hunter",
   DRUID       = "Druid",
   HUNTER      = "Hunter",
   MAGE        = "Mage",
   MONK        = "Monk",
   PALADIN     = "Paladin",
   PRIEST      = "Priest",
   ROGUE       = "Rogue",
   SHAMAN      = "Shaman",
   WARLOCK     = "Warlock",
   WARRIOR     = "Warrior",
}

-- Sorted class order for dropdown display
GearGenieClassOrder = {
   "ASCENSION", "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "HUNTER",
   "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"
}

---------------------------------------------------------------------------
-- Weight profiles: GearGenieDefaultWeights[CLASS][SPEC] = { key = weight }
---------------------------------------------------------------------------
GearGenieDefaultWeights = {
   ["ASCENSION"] = {
      ["None"] = {
         Strength = 1, Agility = 1, Stamina = 0.5, Intellect = 1, Spirit = 1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0.5, Defense = 0.5,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 0.5, Crit = 1.5, SpellCrit = 1.5, Hit = 2, SpellHit = 0,
         Expertise = 1.5, DPS = 1.5,
      },
      ["Strength"] = {
         Strength = 2.02, Agility = 0.5, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0.5, Defense = 4,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 0.88, Crit = 1.34, SpellCrit = 0, Hit = 2, SpellHit = 0,
         Expertise = 1.46, DPS = 1.33333,
      },
      ["Agility"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, SpellCrit = 0, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Intellect"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 0.40, Spirit = 1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.8, SpellPenetration = 0.005, Haste = 1.28, Mp5 = 0.005,
         AttackPower = 0, Crit = 0, SpellCrit = 20, Hit = 0, SpellHit = 10,
         Expertise = 0, DPS = 0.01,
      },
      ["Spirit"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 0.26, Spirit = 1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.75, SpellPenetration = 0, Haste = 2, Mp5 = 4,
         AttackPower = 0, Crit = 0, SpellCrit = 1.6, Hit = 0, SpellHit = 1.95,
         Expertise = 0, DPS = 0.01,
      },
   },
   ["DEATHKNIGHT"] = {
      ["None"] = {
         Strength = 1.05, Agility = 0, Stamina = 0.5, Intellect = 0, Spirit = 0,
         Armor = 1, Dodge = 0.5, Parry = 0.5, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 1, Hit = 0.15, SpellHit = 0,
         Expertise = 0.3, DPS = 2,
      },
      ["Blood"] = {
         Strength = 1.05, Agility = 0, Stamina = 0.5, Intellect = 0, Spirit = 0,
         Armor = 1, Dodge = 0.5, Parry = 0.5, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 1, Hit = 0.15, SpellHit = 0,
         Expertise = 0.3, DPS = 2,
      },
      ["Frost"] = {
         Strength = 1.05, Agility = 0, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 1, Dodge = 0.5, Parry = 0.5, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.22, Mp5 = 0,
         AttackPower = 1, Crit = 1, Hit = 0.15, SpellHit = 0,
         Expertise = 0.3, DPS = 2,
      },
      ["Unholy"] = {
         Strength = 1.05, Agility = 0, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 1, Dodge = 0.5, Parry = 0.5, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 1, Hit = 0.15, SpellHit = 0,
         Expertise = 0.3, DPS = 2,
      },
   },
   ["DEMONHUNTER"] = {
      ["None"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Havoc"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Vengeance"] = {
         Strength = 0, Agility = 1.05, Stamina = 1, Intellect = 0, Spirit = 0,
         Armor = 0.8, Dodge = 0.4, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 0.3, SpellHit = 0,
         Expertise = 0.4, DPS = 2,
      },
   },
   ["DRUID"] = {
      ["None"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.5,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.5, SpellPenetration = 0, Haste = 0.5, Mp5 = 0.05,
         AttackPower = 0, Crit = 0.9, SpellCrit = 0, Hit = 0.9, SpellHit = 0,
         Expertise = 0, DPS = 1,
      },
      ["Balance"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.8, SpellPenetration = 0.1, Haste = 0.8, Mp5 = 0.01,
         AttackPower = 0, Crit = 0.4, SpellCrit = 0, Hit = 0.05, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Feral"] = {
         Strength = 0, Agility = 1.05, Stamina = 1, Intellect = 0, Spirit = 0,
         Armor = 0.8, Dodge = 0.4, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 0.3, SpellHit = 0,
         Expertise = 0.4, DPS = 0.8,
      },
      ["Guardian"] = {
         Strength = 0, Agility = 1.05, Stamina = 1, Intellect = 0, Spirit = 0,
         Armor = 0.8, Dodge = 0.4, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 0.3, SpellHit = 0,
         Expertise = 0.4, DPS = 0.8,
      },
      ["Restoration"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.60,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.85, SpellPenetration = 0, Haste = 0.8, Mp5 = 0.05,
         AttackPower = 0, Crit = 0.6, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
   },
   ["HUNTER"] = {
      ["None"] = {
         Strength = 0.5, Agility = 1.05, Stamina = 0.1, Intellect = 0, Spirit = 0,
         Armor = 0.0001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 0.8, Hit = 0.4, SpellHit = 0,
         Expertise = 0.1, DPS = 2,
      },
      ["Beast Mastery"] = {
         Strength = 0.5, Agility = 1.05, Stamina = 0.1, Intellect = 0, Spirit = 0,
         Armor = 0.0001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.9, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 0.4, SpellHit = 0,
         Expertise = 0.1, DPS = 2,
      },
      ["Marksmanship"] = {
         Strength = 0, Agility = 1.05, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.005, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.61, Mp5 = 0,
         AttackPower = 1, Crit = 1.66, Hit = 3.49, SpellHit = 0,
         Expertise = 0, DPS = 2,
      },
      ["Survival"] = {
         Strength = 0, Agility = 1.05, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.005, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.33, Mp5 = 0,
         AttackPower = 1, Crit = 1.37, Hit = 3.19, SpellHit = 0,
         Expertise = 0, DPS = 2,
      },
   },
   ["MAGE"] = {
      ["None"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 5.16, Spirit = 0.05,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.8, SpellPenetration = 0.005, Haste = 1.28, Mp5 = 0.005,
         AttackPower = 0, Crit = 1.34, SpellCrit = 0, Hit = 3.21, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Arcane"] = {
         Strength = 0, Agility = 0, Stamina = 0.01, Intellect = 1, Spirit = 0,
         Armor = 0.0001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.6, SpellPenetration = 0.2, Haste = 0.5, Mp5 = 0,
         AttackPower = 0, Crit = 0.9, SpellCrit = 0, Hit = 0.7, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Fire"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.05,
         Armor = 0.0001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.8, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 0, Crit = 1.2, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Frost"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.05,
         Armor = 0.0001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.9, SpellPenetration = 0.3, Haste = 0.8, Mp5 = 0,
         AttackPower = 0, Crit = 0.8, SpellCrit = 0, Hit = 0.7, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
   },
   ["MONK"] = {
      ["None"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Brewmaster"] = {
         Strength = 0, Agility = 1.05, Stamina = 1, Intellect = 0, Spirit = 0,
         Armor = 0.8, Dodge = 0.4, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 0.3, SpellHit = 0,
         Expertise = 0.4, DPS = 2,
      },
      ["Windwalker"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Mistweaver"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.60,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.85, SpellPenetration = 0, Haste = 0.8, Mp5 = 0.05,
         AttackPower = 0, Crit = 0.6, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 1,
      },
   },
   ["PALADIN"] = {
      ["None"] = {
         Strength = 2.33, Agility = 0, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.79, Mp5 = 0,
         AttackPower = 1, Crit = 0.98, Hit = 1.77, SpellHit = 0,
         Expertise = 1.3, DPS = 2,
      },
      ["Holy"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 0.8, Spirit = 0.9,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.7, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 0, Crit = 1, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Protection"] = {
         Strength = 1, Agility = 0.3, Stamina = 0.65, Intellect = 0.05, Spirit = 0,
         Armor = 0.05, Dodge = 0.8, Parry = 0.75, Block = 0.8, Defense = 0,
         SpellPower = 0.05, SpellPenetration = 0, Haste = 0.5, Mp5 = 0,
         AttackPower = 0.4, Crit = 0.25, Hit = 0, SpellHit = 0,
         Expertise = 0.2, DPS = 2,
      },
      ["Retribution"] = {
         Strength = 2.33, Agility = 0, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.79, Mp5 = 0,
         AttackPower = 1, Crit = 0.98, Hit = 1.77, SpellHit = 0,
         Expertise = 1.3, DPS = 2,
      },
   },
   ["PRIEST"] = {
      ["None"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.75, SpellPenetration = 0, Haste = 2, Mp5 = 0,
         AttackPower = 0, Crit = 1.6, SpellCrit = 0, Hit = 1.95, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Discipline"] = {
         Strength = 0, Agility = 0, Stamina = 0, Intellect = 1, Spirit = 1,
         Armor = 0.0001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.8, SpellPenetration = 0, Haste = 1, Mp5 = 0,
         AttackPower = 0, Crit = 0.25, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Holy"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 1, SpellPenetration = 0, Haste = 0.47, Mp5 = 0,
         AttackPower = 0, Crit = 0.47, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Shadow"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 1, SpellPenetration = 0, Haste = 1, Mp5 = 0,
         AttackPower = 0, Crit = 1, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
   },
   ["ROGUE"] = {
      ["None"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Assassination"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.1, DPS = 2,
      },
      ["Combat"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Outlaw"] = {
         Strength = 0, Agility = 1.1, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.05, Mp5 = 0,
         AttackPower = 1, Crit = 1.1, Hit = 1.75, SpellHit = 0,
         Expertise = 1.85, DPS = 3.075,
      },
      ["Subtlety"] = {
         Strength = 0.3, Agility = 1.1, Stamina = 0.2, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0.1, Parry = 0.1, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.5, Mp5 = 0,
         AttackPower = 0.4, Crit = 1.1, Hit = 0.6, SpellHit = 0,
         Expertise = 0, DPS = 2,
      },
   },
   ["SHAMAN"] = {
      ["None"] = {
         Strength = 0, Agility = 1, Stamina = 0.05, Intellect = 1, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 1, SpellPenetration = 1, Haste = 1, Mp5 = 0,
         AttackPower = 1, Crit = 1.11, Hit = 2.7, SpellHit = 0,
         Expertise = 0, DPS = 2,
      },
      ["Elemental"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 1,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.6, SpellPenetration = 0.1, Haste = 0.9, Mp5 = 0,
         AttackPower = 0, Crit = 0.9, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 2,
      },
      ["Enhancement"] = {
         Strength = 0, Agility = 1.05, Stamina = 0.1, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.95, Mp5 = 0,
         AttackPower = 1, Crit = 1, Hit = 0.8, SpellHit = 0,
         Expertise = 0.3, DPS = 2,
      },
      ["Restoration"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 1, Spirit = 0.65,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0.75, SpellPenetration = 0, Haste = 0.6, Mp5 = 0,
         AttackPower = 0, Crit = 0.4, SpellCrit = 0, Hit = 0, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
   },
   ["WARLOCK"] = {
      ["None"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 3.68, Spirit = 0.005,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.81, SpellPenetration = 0.05, Haste = 2.32, Mp5 = 0,
         AttackPower = 0, Crit = 1.79, SpellCrit = 0, Hit = 2.78, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Affliction"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 3.68, Spirit = 0.005,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.81, SpellPenetration = 0.05, Haste = 2.32, Mp5 = 0,
         AttackPower = 0, Crit = 1.79, SpellCrit = 0, Hit = 2.78, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Demonology"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 3.79, Spirit = 0.005,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.91, SpellPenetration = 0.05, Haste = 2.37, Mp5 = 0,
         AttackPower = 0, Crit = 1.95, SpellCrit = 0, Hit = 3.74, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
      ["Destruction"] = {
         Strength = 0, Agility = 0, Stamina = 0.05, Intellect = 3.3, Spirit = 0.005,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 2.62, SpellPenetration = 0.05, Haste = 2.08, Mp5 = 0,
         AttackPower = 0, Crit = 1.4, SpellCrit = 0, Hit = 2.83, SpellHit = 0,
         Expertise = 0, DPS = 0.01,
      },
   },
   ["WARRIOR"] = {
      ["None"] = {
         Strength = 2.02, Agility = 0, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 0.88, Crit = 1.34, Hit = 2, SpellHit = 0,
         Expertise = 1.46, DPS = 2,
      },
      ["Arms"] = {
         Strength = 2.02, Agility = 0, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0.8, Mp5 = 0,
         AttackPower = 0.88, Crit = 1.34, Hit = 2, SpellHit = 0,
         Expertise = 1.46, DPS = 2,
      },
      ["Fury"] = {
         Strength = 2.98, Agility = 0, Stamina = 0.05, Intellect = 0, Spirit = 0,
         Armor = 0.001, Dodge = 0, Parry = 0, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 1.37, Mp5 = 0,
         AttackPower = 1.36, Crit = 1.98, Hit = 2.47, SpellHit = 0,
         Expertise = 2.47, DPS = 2,
      },
      ["Protection"] = {
         Strength = 1.2, Agility = 0, Stamina = 1.5, Intellect = 0, Spirit = 0,
         Armor = 0.16, Dodge = 1, Parry = 1.03, Block = 0, Defense = 0,
         SpellPower = 0, SpellPenetration = 0, Haste = 0, Mp5 = 0,
         AttackPower = 0, Crit = 0.4, Hit = 0.02, SpellHit = 0,
         Expertise = 0.04, DPS = 2,
      },
   },
}

---------------------------------------------------------------------------
-- Apply a weight profile to the active statWeightTable + customStatWeigths
---------------------------------------------------------------------------
function GearGenieApplyWeights(className, specName)
   local profile = GearGenieDefaultWeights[className]
      and GearGenieDefaultWeights[className][specName]
   if not profile then
      GearGeniePrint("No weight profile for " .. (className or "?") .. " / " .. (specName or "?"))
      return
   end

   -- Clear and rebuild statWeightTable
   table.wipe(statWeightTable)
   for key, weight in pairs(profile) do
      local globals = GearGenieStatKeyMap[key]
      if globals then
         for _, global in ipairs(globals) do
            if global then
               statWeightTable[global] = weight
            end
         end
      end
   end

   -- Update custom stat weights (DPS, Armor)
   table.wipe(customStatWeigths)
   local idx = 1
   for key, pattern in pairs(GearGenieCustomStatPatterns) do
      local weight = profile[key] or 0
      if weight > 0 then
         customStatWeigths[idx] = {
            Name   = pattern.Name,
            Match  = pattern.Match,
            Weight = weight,
         }
         idx = idx + 1
      end
   end

   GearGeniePrint("Weights loaded: " .. (GearGenieClassNames[className] or className) .. " - " .. specName)
end

---------------------------------------------------------------------------
-- Class / spec detection
---------------------------------------------------------------------------
function GearGenieDetectClass()
   local _, classToken = UnitClass("player")
   if classToken == "HERO" or classToken == "ADVENTURER" then
      -- Classless realm: use ASCENSION + primary stat
      local primStat = UnitPrimaryStat and UnitPrimaryStat("player") or 0
      local specMap = { [1] = "Strength", [2] = "Agility", [3] = "Intellect", [4] = "Spirit" }
      return "ASCENSION", specMap[primStat] or "None"
   else
      return classToken, "None"
   end
end
