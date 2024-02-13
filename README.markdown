# Threat

A World of Warcraft Vanilla (v1.1.12) Addon to simplify Warrior tanking.

Providing warrior tank a single button solution to generate threat on a single target.

Built on Turtle WoW server.


## Installation

Clone the repository into your `Addons` folder:

    cd <WOW_BASE_DIR>/Interface/Addons
    git clone --depth=1 https://github.com/allfoxwy/Threat.git

Create a macro to call `/warrthreat`:

    /warrthreat

Bind the macro to a key and spam it to generate threat.


## Function description
- Announce a message when Taunt resist or Mocking Blow missed
- Announce a countdown when Challenging Shout
- Revenge is used whenever possiable
- Priority Shield Block if HP less than 40%
- Use Shield Block if Bloodthirst and Shield Slam are in cooldown
- Buff self with Battle Shout
- Use Bloodthrist or Shield Slam according to talents
- Sunder Armor would be cast **only once** on engage to generate initial threat to hold mobs away from healer
- After Bloodthrist and Shield Slam are in cooldown, apply Sunder Armor up to 5 stacks. No more than 5 stacks
- Use Heroic Strike when rage more than 45


## Credit

Original addon Threat (https://github.com/muellerj/Threat)

Idea to check taunt resist is taken from Tank buddy (https://github.com/srazdokunebil/TankBuddy)

Idea to check if offhand holding a shield is tanken from Roid Macros (https://denniswg.github.io/Roid-Macros/)

The original addon has not been updated for years. It only support Shield Slam so modern fury-protection tank can't use it.

After fighting against Super Macro's bugs and got slienced by GM because some of my macros misbehaving spam World chat. I decide to make this.

I don't have a druid nor paladin toon. So this addon only work for warriors.

About ethic concerns about this addon might take fun away from tanks:
> Today healers one-key spam QuckHeal (https://github.com/Zebouski/QuickHeal)
>
> DDs one-key spam Execution without reading even nor having a threat meter (https://github.com/balakethelock/TWThreat)
>
> I think tanks should have their own addon to easy their life.


