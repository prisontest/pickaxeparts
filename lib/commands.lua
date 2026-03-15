local OP = prisontest
local PM = OP.parts_mod
local U = rawget(_G, "prisontest_utils")

if not PM.ready then
    return
end

if U and type(U.register_public_command) == "function" then
    U.register_public_command("parts")
end

minetest.register_chatcommand("parts", {
    description = "Open parts UI",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found."
        end
        OP.show_parts_gui(player)
        return true
    end,
})

minetest.register_chatcommand("grantpart", {
    description = "Admin: /grantpart <sell|exp|token> <tier> [player]",
    params = "<sell|exp|token> <tier> [player]",
    func = function(name, param)
        local ok, msg = PM.require_admin(name)
        if not ok then
            return false, msg
        end
        local boost_type, tier_raw, target_name = (param or ""):match("^(%S+)%s+(%S+)%s*(%S*)$")
        boost_type = OP.normalize_boost_type(boost_type)
        local tier = math.max(1, math.floor(tonumber(tier_raw) or 0))
        if tier <= 0 then
            return false, "Tier must be >= 1."
        end
        local target, err = PM.resolve_target(name, target_name)
        if not target then
            return false, err
        end
        local slot = PM.slots[math.random(1, #PM.slots)]
        local boost = PM.random_boost_for_tier(tier)
        local stack = OP.make_part_item(tier, slot, true, boost_type, boost)
        PM.give_item(target, stack)
        local PS = rawget(_G, "prisontest_server")
        if PS and type(PS.audit_log) == "function" then
            PS.audit_log("grant_part", name, target:get_player_name(), {
                tier = tier,
                slot = slot,
                boost_type = boost_type,
                boost = boost,
            })
        end
        return true, string.format("Granted part to %s: T%d %s (%s).", target:get_player_name(), tier, slot, OP.boost_type_label(boost_type))
    end,
})
