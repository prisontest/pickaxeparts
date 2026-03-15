local OP = prisontest
local PM = OP.parts_mod

if not PM.ready then
    return
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= PM.formname then
        return false
    end
    if fields.quit or fields.close then
        OP.show_pickaxe_menu(player)
        return true
    end
    if fields.prestige_parts then
        PM.with_action_lock(player, "parts_prestige", function()
            local _, msg = PM.prestige_parts(player)
            minetest.chat_send_player(player:get_player_name(), msg)
            OP.show_parts_gui(player)
        end)
    end
    return true
end)
