local OP = prisontest
local PM = OP.parts_mod

local H = OP.ui_helpers or {}
local U = rawget(_G, "prisontest_utils")

PM.with_action_lock = H.with_action_lock
PM.held_pick = H.held_pick
PM.require_held_pick = H.require_held_pick
PM.set_pick = H.set_pick
PM.read_payload = H.read_payload
PM.player_by_name = H.player_by_name

PM.ready = type(PM.with_action_lock) == "function" and type(PM.held_pick) == "function"

function PM.required_part_tier(parts_prestige)
    return math.max(1, math.floor(tonumber(parts_prestige) or 0) + 1)
end

PM.require_admin = function(name)
    return U.require_mod_priv(name, "prisontest_pickaxeparts")
end
PM.resolve_target = U.resolve_target
PM.random_boost_for_tier = U.random_boost_for_tier
PM.give_item = U.give_item
