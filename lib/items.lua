local OP = prisontest
local PM = OP.parts_mod
local U = rawget(_G, "prisontest_utils")

local PART_SLOTS = (PM and PM.slots) or {"head", "binding", "rod"}
local tier_percent_range = U.tier_percent_range
local give_item = U and U.give_item

local function register_message_settings()
    if type(OP.register_message_setting) ~= "function" then
        return
    end
    OP.register_message_setting("part_finder_proc_messages", "Part finder proc")
end
if minetest.register_on_mods_loaded then
    minetest.register_on_mods_loaded(register_message_settings)
else
    register_message_settings()
end

if not give_item then
    give_item = function(player, stack)
        local inv = player:get_inventory()
        if inv:room_for_item("main", stack) then
            inv:add_item("main", stack)
        else
            minetest.add_item(player:get_pos(), stack)
        end
    end
end

local function round3(n)
    return math.floor((tonumber(n) or 0) * 1000 + 0.5) / 1000
end

local function tier_prefix(tier)
    local t = math.max(1, math.floor(tonumber(tier) or 1))
    local color = minetest.get_color_escape_sequence(OP.tier_color_hex(t))
    local white = minetest.get_color_escape_sequence("#ffffff")
    return color .. "T" .. tostring(t) .. " " .. white
end

local function write_payload(stack, payload)
    if type(OP.write_item_payload) == "function" then
        OP.write_item_payload(stack, payload)
    else
        stack:get_meta():set_string("prisontest:item_payload", minetest.serialize(payload))
    end
end

local function is_main_inventory_full(player)
    local inv = player:get_inventory()
    local list = inv:get_list("main") or {}
    for _, st in ipairs(list) do
        if st:is_empty() then
            return false
        end
    end
    return true
end

local function play_id_sound(user)
    if U and U.play_sound then
        U.play_sound(user, "default_place_node_hard", 0.25)
        return
    end
    minetest.sound_play("default_place_node_hard", {
        to_player = user:get_player_name(),
        gain = 0.25,
    })
end

function OP.make_part_item(tier, slot, identified, boost_type, boost)
    local stack = ItemStack("prisontest:pick_part")
    local payload = {
        tier = math.max(1, math.floor(tonumber(tier) or 1)),
        identified = identified == true,
        slot = slot,
        boost_type = boost_type,
        boost = tonumber(boost) or 0,
    }
    if not payload.identified then
        payload.slot = nil
        payload.boost_type = nil
        payload.boost = 0
    else
        payload.slot = payload.slot or PART_SLOTS[math.random(1, #PART_SLOTS)]
        payload.boost_type = OP.normalize_boost_type(payload.boost_type or OP.random_boost_type())
        payload.boost = round3(payload.boost)
    end
    write_payload(stack, payload)

    local part_texture = "prisontest_pick_part.png"
    if payload.identified then
        if payload.slot == "head" then
            part_texture = "prisontest_pick_part_head.png"
        elseif payload.slot == "rod" then
            part_texture = "prisontest_pick_part_rod.png"
        elseif payload.slot == "binding" then
            part_texture = "prisontest_pick_part_binding.png"
        end
    end

    stack:get_meta():set_string(
        "inventory_image",
        part_texture .. "^[colorize:" .. OP.tier_color_hex(payload.tier) .. ":90"
    )

    if payload.identified then
        local part_name = payload.slot:gsub("^%l", string.upper)
        local pct = math.floor(payload.boost * 100 + 0.5)
        stack:get_meta():set_string(
            "description",
            string.format("%s%s Part\n+%d%% %s", tier_prefix(payload.tier), part_name, pct, OP.boost_type_label(payload.boost_type))
        )
    else
        stack:get_meta():set_string(
            "description",
            string.format("%sUnidentified Part\nLeft-click to identify", tier_prefix(payload.tier))
        )
    end

    return stack
end

minetest.register_craftitem(":prisontest:pick_part", {
    description = "Pickaxe Part",
    inventory_image = "prisontest_pick_part.png",
    stack_max = 64,
    on_use = function(itemstack, user)
        if not user or not user:is_player() then
            return itemstack
        end
        local payload = OP.read_item_payload(itemstack)
        if payload.identified then
            return itemstack
        end
        payload.slot = payload.slot or PART_SLOTS[math.random(1, #PART_SLOTS)]
        payload.identified = true
        payload.boost_type = OP.random_boost_type()
        local tier = math.max(1, math.floor(tonumber(payload.tier) or 1))
        local minp, maxp = tier_percent_range(tier)
        payload.boost = (minp + (math.random() * (maxp - minp))) / 100
        payload.boost = round3(payload.boost)
        local idstack = OP.make_part_item(payload.tier, payload.slot, true, payload.boost_type, payload.boost)
        if itemstack:get_count() > 1 then
            if is_main_inventory_full(user) then
                minetest.chat_send_player(user:get_player_name(), "Inventory is full. Free a slot first.")
                return itemstack
            end
            itemstack:take_item(1)
            user:get_inventory():set_stack("main", user:get_wield_index(), itemstack)
            give_item(user, idstack)
            play_id_sound(user)
            return itemstack
        end
        play_id_sound(user)
        return idstack
    end,
})

function OP.give_part_drop(player, tier)
    local slot = PART_SLOTS[math.random(1, #PART_SLOTS)]
    give_item(player, OP.make_part_item(tier, slot, false))
    if type(OP.send_message_if_enabled) == "function" then
        OP.send_message_if_enabled(player, "part_finder_proc_messages", "You found a pickaxe part!", "#ffd38a")
    end
end

local function normalize_part_stack(stack)
    if stack:get_name() ~= "prisontest:pick_part" then
        return nil
    end
    local payload = OP.read_item_payload(stack)
    local tier = math.max(1, math.floor(tonumber(payload.tier) or 1))
    if payload.identified == true then
        return OP.make_part_item(tier, payload.slot, true, payload.boost_type, payload.boost)
    end
    return OP.make_part_item(tier, nil, false)
end

if type(OP.register_special_item_normalizer) == "function" then
    OP.register_special_item_normalizer(normalize_part_stack)
end
