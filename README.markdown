# Threat

Addon for Warrior tank in World of Warcraft Vanilla (v1.12):
1. Announce messages to `say` channel for important tank events
1. Providing a new slash command which would help tanking skill rotation

Built on Turtle WoW server. If you have issue report you could reply to this thread: https://forum.turtle-wow.org/viewtopic.php?t=13085


## Installation

1. Download ZIP or clone the repository into your `Addons` folder.

1. Announcing function would be triggered by certain game events. No need to setup anything.

1. Tanking rotation could be done by calling `/warrthreat` slash command. Each time it is called it would try perform 1 action in the rotation. Recommended usage is to make a macro with a single line `/warrthreat`, then bind the macro to a key and repeatly press it during engage.

1. Auto attack when `/warrthreat` require putting Attack action from spell book onto an action bar slot. Any slot would do.

1. In case you perfer doing rotation yourself but would like to have announcements, you could ignore the slash command not using it at all. Announcements still work.


## Function description
- Announce a message when Taunt resist or Mocking Blow missed
- Announce a message when Shield Wall or Last Stand, and another message 3 sec before they ends.
- Announce a countdown when Challenging Shout
- Revenge is used when possible
- Prioritise Shield Block if HP less than 40%
- Sunder Armor would be cast **once** on engage to generate initial threat to hold mobs away from healer
- Buff self with Battle Shout
- Attempt to Disarm Elite or World Boss. However if the attempt failed because of immune, this event would be recorded and would not attempt again.
- When HP less than 85%, use Shield Block if target enemy is targeting player.
- Apply Sunder Armor up to 5 stacks. Refresh after 25 seconds
- Use Bloodthrist or Shield Slam according to talents
- Use Heroic Strike when rage overflow
    - If you don't have a shield in offhand, certain action would be skipped. Sure you could switch shield on during combat and call the rotation again.
    - Battle Shout might fail due to silence but you could keep call the rotation. It would be retried later.

## Edit message words
All `say` messages are saved in Localization.lua:
> <WoW_game_folder>/Interface/AddOns/Threat/Localization.lua

You could edit MESSAGE_ strings in it. Keep it English only as server might refuse non-English words.

## Reset known Disarm immune table
While it's a rare situation, server update might require a reset on locally-saved known Disarm immune table.

Like all WoW addon, it is saved in WTF folder:
> <WoW_game_folder>/WTF/Account/<Your_account_name>/SavedVariables/Threat.lua

To reset the table, you could delete the file.


## Credit

Original addon: Threat (https://github.com/muellerj/Threat)

Idea to check if taunt was resisted is taken from Tank buddy (https://github.com/srazdokunebil/TankBuddy)

Idea to check if offhand is holding a shield is taken from Roid Macros (https://denniswg.github.io/Roid-Macros/)

The original addon has not been updated for years. It only support Shield Slam so modern fury-protection tank can't use it.

After fighting against Super Macro's bugs and got slienced by GM because some of my macros misbehaving spam World chat. I decide to make this.

I don't have a druid nor paladin toon. So this addon only work for warriors.

About ethic concerns about this addon might take fun away from tanks:
> Today healers one-key spam QuckHeal (https://github.com/Zebouski/QuickHeal)
>
> DDs one-key spam Execution without reading even nor having a threat meter (https://github.com/balakethelock/TWThreat)
>
> I think tanks should have their own addon to easy their life.


