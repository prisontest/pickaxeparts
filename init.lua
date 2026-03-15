local OP = rawget(_G, "prisontest")
if type(OP) ~= "table" then
    return
end

if type(OP.enable_feature) == "function" then
    OP.enable_feature("pickaxeparts")
end

local MODPATH = minetest.get_modpath(minetest.get_current_modname())
OP.parts_mod = {
    modpath = MODPATH,
    formname = "prisontest:parts_gui",
    slots = {"head", "binding", "rod"},
}

for _, rel in ipairs({
    "lib/helpers.lua",
    "lib/items.lua",
    "lib/config.lua",
    "lib/ui.lua",
    "lib/commands.lua",
    "lib/handlers.lua",
}) do
    dofile(MODPATH .. "/" .. rel)
end
