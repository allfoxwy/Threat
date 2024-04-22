# Threat

Addon to simplify Warrior tanking for World of Warcraft Vanilla (v1.12).

Providing warrior tank a single button solution to generate threat on a single target.

Built on Turtle WoW server. If you have issue report you could reply to this thread: https://forum.turtle-wow.org/viewtopic.php?t=13085


## Installation

Clone the repository into your `Addons` folder:

    cd <WoW_game_folder>/Interface/Addons
    git clone --depth=1 https://github.com/allfoxwy/Threat.git

Create a macro to call `/warrthreat`:

    /warrthreat

Bind the macro to a key and repeatly press it to generate threat.


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


## Reset known Disarm immune table
Like all WoW addon, it is saved in WTF folder:

    <WoW_game_folder>/WTF/Account/<Your_account_name>/SavedVariables/Threat.lua

In case you need reset the table, you could delete the file.


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


