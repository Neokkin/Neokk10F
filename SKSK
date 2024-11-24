local combinations = {
    {"Water", "Water"}, {"Magic", "Magic"}, {"Punch", "Punch"}, {"Wind", "Wind"}, {"Flame", "Flame"},
    {"Water", "Magic"}, {"Water", "Flame"}, {"Magic", "Wind"}, {"Magic", "Flame"}, {"Punch", "Wind"},
    {"Wind", "Flame"}, {"CrystalBall", "Magic"}, {"Storm", "Wind"}, {"Poison", "Magic"}, {"Ice", "Punch"},
    {"Light", "Magic"}, {"Light", "Flame"}, {"CrystalBall", "Flame"}, {"WildFire", "Magic"}, {"Kick", "Punch"},
    {"Tomado", "Water"}, {"Light", "Light"}, {"Ice", "Ice"}, {"Kick", "Kick"}, {"Rain", "Poison"},
    {"Rain", "Lava"}, {"FlyingPunch", "Lava"}, {"Ice", "Storm"}, {"Music", "Wind"}, {"Music", "Magic"},
    {"Fog", "Magic"}, {"Stomp", "Wind"}, {"Sun", "Water"}, {"Waterspout", "Water"}, {"Supernatural", "CrystalBall"},
    {"Sun", "Rain"}, {"Sun", "Lava"}, {"Supernatural", "Light"}, {"Electricity", "Electricity"},
    {"Disease", "Disease"}, {"Darkness", "Darkness"}, {"Explosive", "Explosive"}, {"Freeze", "Blizzard"},
    {"Sun", "Explosive"}, {"Energy", "Magic"}, {"Plant", "Flame"}, {"Plant", "Wind"}, {"Tsunami", "Water"},
    {"Crush", "Water"}, {"Plant", "Water"}, {"Plant", "Magic"}, {"Rainbow", "Magic"}, {"Melt", "Storm"},
    {"Tsunami", "Lava"}, {"Plant", "Darkness"}, {"Melt", "Disease"}, {"Night", "Sun"}, {"Supernova", "Darkness"},
    {"Blackhole", "Magic"}, {"Love", "Poison"}, {"Love", "Light"}, {"Earth", "Lava"}, {"Blackhole", "Light"},
    {"Erode", "Explosive"}, {"Life", "Supernatural"}, {"Life", "Darkness"}, {"Leaves", "Darkness"}, {"Earth", "Plant"},
    {"Slime", "Bomb"}, {"Vines", "Fairy"}, {"Life", "Energy"}, {"Blackhole", "Supernova"}, {"Love", "Love"},
    {"Erode", "Earth"}, {"Earth", "Love"}, {"Life", "Snowball"}, {"Life", "Ocean"}, {"Earthquake", "Magic"},
    {"Rock", "Lava"}, {"Forest", "Sun"}, {"Heal", "Electricity"}, {"Angel", "Darkness"}, {"Steel", "Slap"},
    {"Celebrate", "Music"}, {"Angel", "Night"}, {"StickyBomb", "Plague"}, {"Space", "Earth"}, {"Winter", "Summer"},
    {"Space", "Life"}, {"Time", "Spider"}, {"Steel", "Steel"}, {"Silk", "Magic"}, {"Demon", "Supernatural"},
    {"Katana", "Stealth"}, {"Alien", "Steel"}, {"Demon", "Nuclear"}, {"Stardust", "Flame"}, {"Nana", "FlyingPunch"},
    {"Stardust", "Music"}, {"Mana", "Stealth"}, {"Mana", "Ocean"}, {"Stardust", "Erode"}, {"Mana", "Fish"},
    {"Mana", "Death"}, {"Mana", "Crystal"}, {"Mana", "Shield"}, {"Mana", "SuperHeal"}, {"Void", "Ufo"},
    {"Mana", "Stardust"}, {"Void", "Stardust"}, {"Comet", "Explosive"}, {"Sand", "Waffle"}, {"Glove", "Steel"},
    {"Medic", "Void"}, {"Puffer", "Void"}, {"Sand", "Mana"}
}

local generatedCode = ""

for i, combo in ipairs(combinations) do
    generatedCode = generatedCode .. string.format([[
local args = {
    [1] = "%s",
    [2] = "%s"
}

game:GetService("ReplicatedStorage").Remotes.Ability.Merge:InvokeServer(unpack(args))
task.wait(0.5)
]], combo[1], combo[2])
end

print(generatedCode)

