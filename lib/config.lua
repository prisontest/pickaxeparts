local OP = prisontest
local PM = OP.parts_mod
local U = rawget(_G, "prisontest_utils")

local function load_config()
    if not U or type(U.load_json_config) ~= "function" then
        return nil
    end
    return U.load_json_config({
        tag = "prisontest_pickaxeparts",
        modpath = PM.modpath,
        relpath = "data/config.json",
        schema = {type = "table"},
    })
end

function PM.apply_config()
    local cfg = load_config()
    if type(cfg) ~= "table" then
        return
    end
    OP.parts_addon_config = cfg
    OP.partfinder_settings = cfg.finder or {}

    if type(OP.register_enchant_def) == "function" and type(cfg.enchant) == "table" then
        OP.register_enchant_def("partfinder", cfg.enchant, {after = tostring(cfg.order_after or "tokengreed")})
    end
    if type(OP.register_enchant_visibility) == "function" then
        OP.register_enchant_visibility("partfinder", function()
            return true
        end)
    end
end

PM.apply_config()
minetest.register_on_mods_loaded(function()
    PM.apply_config()
end)
if type(OP.register_config_reload_hook) == "function" then
    OP.register_config_reload_hook(PM.apply_config)
end
