local OP = prisontest
local PM = OP.parts_mod
local U = rawget(_G, "prisontest_utils")

if not PM.ready then
    return
end

local function prestige_parts(player)
    local stack = PM.held_pick(player)
    if not stack then
        return false, "Hold your prison pickaxe."
    end
    local profile = OP.get_pick_profile(stack)
    local required_tier = PM.required_part_tier(profile.parts_prestige)
    for _, slot in ipairs(PM.slots) do
        local part = profile.parts[slot]
        if part == nil then
            return false, "Equip all three parts first."
        end
        local part_tier = math.max(1, math.floor(tonumber(part.tier) or 1))
        if part_tier ~= required_tier then
            return false, string.format("All parts must be T%d to prestige (your %s is T%d).", required_tier, slot, part_tier)
        end
    end
    profile.parts.head = nil
    profile.parts.binding = nil
    profile.parts.rod = nil
    profile.parts_prestige = profile.parts_prestige + 1
    OP.set_pick_profile(stack, profile)
    PM.set_pick(player, stack)
    return true, "Parts prestiged. Equipped parts consumed."
end

local function parts_inv_name(player_name)
    return "prisontest:parts_slots_" .. player_name
end

local function ensure_parts_slot_inv(player)
    local pname = player:get_player_name()
    local name = parts_inv_name(pname)
    local inv = minetest.get_inventory({type = "detached", name = name})
    if inv then
        return name, inv
    end
    inv = minetest.create_detached_inventory(name, {
        allow_put = function(_, listname, index, stack, player_ref)
            if listname ~= "slots" then return 0 end
            if not player_ref or not player_ref:is_player() then return 0 end
            if stack:get_name() ~= "prisontest:pick_part" then return 0 end
            local payload = PM.read_payload(stack)
            if not (payload.identified and payload.slot and payload.boost_type and payload.boost) then
                return 0
            end
            local pick = PM.held_pick(player_ref)
            if not pick then return 0 end
            local profile = OP.get_pick_profile(pick)
            local idx = payload.slot == "head" and 1 or (payload.slot == "binding" and 2 or (payload.slot == "rod" and 3 or 0))
            if idx == 0 then
                return 0
            end
            if idx ~= index then
                return 0
            end
            return 1
        end,
        allow_take = function(_, listname, index, _, player_ref)
            if listname ~= "slots" then return 0 end
            if not player_ref or not player_ref:is_player() then return 0 end
            local slot = PM.slots[index]
            if not slot then return 0 end
            local pick = PM.held_pick(player_ref)
            if not pick then return 0 end
            local profile = OP.get_pick_profile(pick)
            if not profile.parts[slot] then
                return 0
            end
            return 1
        end,
        on_put = function(invref, _, index, stack, player_ref)
            if not player_ref or not player_ref:is_player() then
                invref:set_stack("slots", index, "")
                return
            end
            PM.with_action_lock(player_ref, "parts_equip", function()
                local pick = PM.held_pick(player_ref)
                if not pick then
                    invref:set_stack("slots", index, "")
                    return
                end
                local payload = PM.read_payload(stack)
                local profile = OP.get_pick_profile(pick)
                profile.parts[payload.slot] = {
                    tier = payload.tier or 1,
                    boost_type = payload.boost_type,
                    boost = payload.boost,
                }
                OP.set_pick_profile(pick, profile)
                PM.set_pick(player_ref, pick)
                if U and U.play_equip_sound then
                    U.play_equip_sound(player_ref)
                end
                invref:set_stack("slots", index, OP.make_part_item(payload.tier or 1, payload.slot, true, payload.boost_type, payload.boost))
                OP.show_parts_gui(player_ref)
            end)
        end,
        on_take = function(invref, _, index, _, player_ref)
            if not player_ref or not player_ref:is_player() then
                return
            end
            PM.with_action_lock(player_ref, "parts_unequip", function()
                local slot = PM.slots[index]
                if not slot then
                    return
                end
                local pick = PM.held_pick(player_ref)
                if not pick then
                    return
                end
                local profile = OP.get_pick_profile(pick)
                profile.parts[slot] = nil
                OP.set_pick_profile(pick, profile)
                PM.set_pick(player_ref, pick)
                if U and U.play_equip_sound then
                    U.play_equip_sound(player_ref)
                end
                invref:set_stack("slots", index, "")
                OP.show_parts_gui(player_ref)
            end)
        end,
    })
    inv:set_size("slots", 3)
    return name, inv
end

function OP.show_parts_gui(player)
    local stack = PM.require_held_pick(player)
    if not stack then
        return
    end
    local p = OP.get_pick_profile(stack)
    local parts_name, parts_inv = ensure_parts_slot_inv(player)
    parts_inv:set_list("slots", {
        p.parts.head and OP.make_part_item(p.parts.head.tier or 1, "head", true, p.parts.head.boost_type, p.parts.head.boost) or ItemStack(""),
        p.parts.binding and OP.make_part_item(p.parts.binding.tier or 1, "binding", true, p.parts.binding.boost_type, p.parts.binding.boost) or ItemStack(""),
        p.parts.rod and OP.make_part_item(p.parts.rod.tier or 1, "rod", true, p.parts.rod.boost_type, p.parts.rod.boost) or ItemStack(""),
    })
    local fs = table.concat({
        "formspec_version[4]",
        "size[12.0,11.2]",
        "label[0.5,0.5;Pickaxe Parts]",
        "label[0.5,0.9;Equipped Slots (drag in/out)]",
        "label[4.3,1.25;Head]",
        "list[detached:" .. parts_name .. ";slots;5.4,1.05;1,1;0]",
        "label[4.3,2.45;Binding]",
        "list[detached:" .. parts_name .. ";slots;5.4,2.25;1,1;1]",
        "label[4.3,3.65;Rod]",
        "list[detached:" .. parts_name .. ";slots;5.4,3.45;1,1;2]",
        "label[0.5,1.6;Parts Prestige: P" .. tostring(PM.required_part_tier(p.parts_prestige)) .. "]",
        "button[0.5,2.05;2.7,0.9;prestige_parts;Prestige Parts]",
        "label[0.5,5.1;Inventory]",
        "list[current_player;main;1.1,5.5;8,4;]",
        "listring[]",
        "button_exit[10.5,0.4;1.1,0.8;close;Back]",
    })
    minetest.show_formspec(player:get_player_name(), PM.formname, fs)
end

PM.prestige_parts = prestige_parts
