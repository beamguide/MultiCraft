--From Stamina mod
--Copyright (C) BlockMen (2013-2015)
--Copyright (C) Auke Kok <sofar@foo-projects.org> (2016)
--Copyright (C) Minetest Mods Team (2016-2019)
--Copyright (C) MultiCraft Development Team (2016-2019)

--This program is free software; you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation; either version 3.0 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License along
--with this program; if not, write to the Free Software Foundation, Inc.,
--51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

if not core.settings:get_bool("enable_damage") then
	return
end

hunger = {}

local function get_setting(key, default)
	local setting = core.settings:get("hunger." .. key)
	return tonumber(setting) or default
end

hunger.settings = {
	-- see settingtypes.txt for descriptions
	tick = get_setting("tick", 600),
	tick_min = get_setting("tick_min", 4),
	health_tick = get_setting("health_tick", 4),
	move_tick = get_setting("move_tick", 0.5),
	poison_tick = get_setting("poison_tick", 1),
	exhaust_dig = get_setting("exhaust_dig", 2),
	exhaust_place = get_setting("exhaust_place", 1),
	exhaust_move = get_setting("exhaust_move", 2),
	exhaust_jump = get_setting("exhaust_jump", 4),
	exhaust_craft = get_setting("exhaust_craft", 2),
	exhaust_punch = get_setting("exhaust_punch", 5),
	exhaust_lvl = get_setting("exhaust_lvl", 192),
	heal = get_setting("heal", 1),
	heal_lvl = get_setting("heal_lvl", 5),
	starve = get_setting("starve", 1),
	starve_lvl = get_setting("starve_lvl", 3),
	level_max = get_setting("level_max", 21),
	visual_max = get_setting("visual_max", 20)
}
local settings = hunger.settings

local attribute = {
	saturation = "hunger:level",
	poisoned = "hunger:poisoned",
	exhaustion = "hunger:exhaustion",
}

local function is_player(player)
	return (
		player and
		not player.is_fake_player and
		player.get_attribute and  -- check for pipeworks fake player
		player.is_player and
		player:is_player())
end

local function get_int_attribute(player, key)
	local level = player:get_attribute(key)
	if level then
		return tonumber(level)
	else
		return nil
	end
end

--- SATURATION API ---
function hunger.get_saturation(player)
	return get_int_attribute(player, attribute.saturation)
end

function hunger.set_saturation(player, level)
	player:set_attribute(attribute.saturation, level)
	hud.change_item(player, "hunger", {number = math.min(settings.visual_max, level)})
end

hunger.registered_on_update_saturations = {}
function hunger.register_on_update_saturation(fun)
	table.insert(hunger.registered_on_update_saturations, fun)
end

function hunger.update_saturation(player, level)
	for _, callback in pairs(hunger.registered_on_update_saturations) do
		local result = callback(player, level)
		if result then
			return result
		end
	end

	local old = hunger.get_saturation(player)

	if not old or old == level then  -- To suppress HUD update
		return
	end

	-- players without interact priv cannot eat
	if old < settings.heal_lvl and not core.check_player_privs(player, {interact=true}) then
		return
	end

	hunger.set_saturation(player, level)
end

function hunger.change_saturation(player, change)
	if not is_player(player) or not change or change == 0 then
		return false
	end
	local level = hunger.get_saturation(player) + change or 0
	level = math.max(level, 0)
	level = math.min(level, settings.level_max)
	hunger.update_saturation(player, level)
	return true
end

hunger.change = hunger.change_saturation -- for backwards compatablity
--- END SATURATION API ---

--- POISON API ---
function hunger.is_poisoned(player)
	return player:get_attribute(attribute.poisoned) == "yes"
end

function hunger.set_poisoned(player, poisoned)
	if poisoned then
		hud.change_item(player, "hunger", {text = "hunger_statbar_poisen.png"})
		player:set_attribute(attribute.poisoned, "yes")
	else
		hud.change_item(player, "hunger", {text = "hunger_statbar_fg.png"})
		player:set_attribute(attribute.poisoned, "no")
	end
end

local function poison_tick(player, ticks, interval, elapsed)
	if not hunger.is_poisoned(player) then
		return
	elseif elapsed > ticks then
		hunger.set_poisoned(player, false)
	else
		local hp = player:get_hp() - 1
		if hp > 0 then
			player:set_hp(hp)
		end
		core.after(interval, poison_tick, player, ticks, interval, elapsed + 1)
	end
end

hunger.registered_on_poisons = {}
function hunger.register_on_poison(fun)
	table.insert(hunger.registered_on_poisons, fun)
end

function hunger.poison(player, ticks, interval)
	for _, fun in pairs(hunger.registered_on_poisons) do
		local rv = fun(player, ticks, interval)
		if rv == true then
			return
		end
	end
	if not is_player(player) then
		return
	end
	hunger.set_poisoned(player, true)
	poison_tick(player, ticks, interval, 0)
end
--- END POISON API ---

--- EXHAUSTION API ---
hunger.exhaustion_reasons = {
	craft = "craft",
	dig = "dig",
	heal = "heal",
	jump = "jump",
	move = "move",
	place = "place",
	punch = "punch",
}

function hunger.get_exhaustion(player)
	return get_int_attribute(player, attribute.exhaustion)
end

function hunger.set_exhaustion(player, exhaustion)
	player:set_attribute(attribute.exhaustion, exhaustion)
end

hunger.registered_on_exhaust_players = {}
function hunger.register_on_exhaust_player(fun)
	table.insert(hunger.registered_on_exhaust_players, fun)
end

function hunger.exhaust_player(player, change, cause)
	for _, callback in pairs(hunger.registered_on_exhaust_players) do
		local result = callback(player, change, cause)
		if result then
			return result
		end
	end

	if not is_player(player) then
		return
	end

	local exhaustion = hunger.get_exhaustion(player) or 0

	exhaustion = exhaustion + change

	if exhaustion >= settings.exhaust_lvl then
		exhaustion = exhaustion - settings.exhaust_lvl
		hunger.change(player, -1)
	end

	hunger.set_exhaustion(player, exhaustion)
end
--- END EXHAUSTION API ---

-- Time based hunger functions
local function move_tick()
	for _, player in pairs(core.get_connected_players()) do
		local controls = player:get_player_control()
		local is_moving = controls.up or controls.down or controls.left or controls.right
		local velocity = player:get_player_velocity()
		velocity.y = 0
		local horizontal_speed = vector.length(velocity)
		local has_velocity = horizontal_speed > 0.05

		if controls.jump then
			hunger.exhaust_player(player, settings.exhaust_jump, hunger.exhaustion_reasons.jump)
		elseif is_moving and has_velocity then
			hunger.exhaust_player(player, settings.exhaust_move, hunger.exhaustion_reasons.move)
		end

	end
end

local function hunger_tick()
	-- lower saturation by 1 point after settings.tick second(s)
	for _, player in pairs(core.get_connected_players()) do
		local saturation = hunger.get_saturation(player) or 0
		if saturation > settings.tick_min then
			hunger.update_saturation(player, saturation - 1)
		end
	end
end

local function health_tick()
	-- heal or damage player, depending on saturation
	for _, player in pairs(core.get_connected_players()) do
		local air = player:get_breath() or 0
		local hp = player:get_hp() or 0
		local saturation = hunger.get_saturation(player) or 0

		-- don't heal if dead, drowning, or poisoned
		local should_heal = (
			saturation >= settings.heal_lvl and
			hp > 0 and
			hp < 20 and
			air > 0
			and not hunger.is_poisoned(player)
		)
		-- or damage player by 1 hp if saturation is < 2 (of 30)
		local is_starving = (
			saturation < settings.starve_lvl and
			hp > 0
		)

		if should_heal then
			player:set_hp(hp + settings.heal)
		elseif is_starving then
			player:set_hp(hp - settings.starve)
		end
	end
end

local hunger_timer = 0
local health_timer = 0
local action_timer = 0

local function hunger_globaltimer(dtime)
	hunger_timer = hunger_timer + dtime
	health_timer = health_timer + dtime
	action_timer = action_timer + dtime

	if action_timer > settings.move_tick then
		action_timer = 0
		move_tick()
	end

	if hunger_timer > settings.tick then
		hunger_timer = 0
		hunger_tick()
	end

	if health_timer > settings.health_tick then
		health_timer = 0
		health_tick()
	end
end

function core.do_item_eat(hp_change, replace_with_item, poison, itemstack, player, pointed_thing)
	for _, callback in pairs(core.registered_on_item_eats) do
		local result = callback(hp_change, replace_with_item, poison, itemstack, player, pointed_thing)
		if result then
			return result
		end
	end

	if not is_player(player) or not itemstack then
		return itemstack
	end

	if not poison then
		hunger.change_saturation(player, hp_change)
		hunger.set_exhaustion(player, 0)
	else
		hunger.change_saturation(player, hp_change)
		hunger.poison(player, -poison, settings.poison_tick)
	end

	itemstack:take_item()

	if replace_with_item then
		if itemstack:is_empty() then
			itemstack:add_item(replace_with_item)
		else
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name=replace_with_item}) then
				inv:add_item("main", replace_with_item)
			else
				local pos = player:getpos()
				pos.y = math.floor(pos.y - 1.0)
				core.add_item(pos, replace_with_item)
			end
		end
	end

	return itemstack
end

hud.register("hunger", {
	hud_elem_type = "statbar",
	position      = {x = 0.5, y = 1},
	alignment     = {x = -1,  y = -1},
	offset        = {x = 8,   y = -94},
	size          = {x = 24,  y = 24},
	text          = "hunger_statbar_fg.png",
	background    = "hunger_statbar_bg.png",
	number        = 20
})

core.register_on_joinplayer(function(player)
	core.after(0.5, function()
		local level = hunger.get_saturation(player) or settings.level_max
		hunger.set_saturation(player, level)
		-- reset poisoned
		player:set_attribute(attribute.poisoned, "no")
	end)
end)

core.register_globalstep(hunger_globaltimer)

core.register_on_placenode(function(_, _, player)
	hunger.exhaust_player(player, settings.exhaust_place, hunger.exhaustion_reasons.place)
end)
core.register_on_dignode(function(_, _, player)
	hunger.exhaust_player(player, settings.exhaust_dig, hunger.exhaustion_reasons.dig)
end)
core.register_on_craft(function(_, player)
	hunger.exhaust_player(player, settings.exhaust_craft, hunger.exhaustion_reasons.craft)
end)
core.register_on_punchplayer(function(_, hitter)
	hunger.exhaust_player(hitter, settings.exhaust_punch, hunger.exhaustion_reasons.punch)
end)
core.register_on_respawnplayer(function(player)
	hunger.update_saturation(player, settings.level_max)
end)
