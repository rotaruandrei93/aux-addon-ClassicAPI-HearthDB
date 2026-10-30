module 'aux'

local T = require 'T'

-- Colors registered with a key can be recolored by the active theme (see set_color_theme).
local dynamic, defaults = {}, {}

function C(r, g, b, a, key)
	local mt = T.map('__metatable', false, '__newindex', pass, 'color', T.list(r, g, b, a))
	if key then
		dynamic[key] = mt.color
		defaults[key] = {r, g, b, a}
	end
	function mt:__call(text)
		local r, g, b, a = unpack(mt.color)
		if text then
			return format('|c%02X%02X%02X%02X', a, r, g, b) .. text .. FONT_COLOR_CODE_CLOSE
		else
			return r/255, g/255, b/255, a
		end
	end
	function mt:__concat(text)
		local r, g, b, a = unpack(mt.color)
		return format('|c%02X%02X%02X%02X', a, r, g, b) .. text
	end
	return setmetatable(T.acquire(), mt)
end

M.color = immutable-{
	none = setmetatable({}, {__metatable=false, __newindex=pass, __call=function(_, v) return v end, __concat=function(_, v) return v end}),
	text = immutable-{enabled = C(255, 254, 250, 1), disabled = C(147, 151, 139, 1)},
	label = immutable-{enabled = C(216, 225, 211, 1), disabled = C(150, 148, 140, 1)},
	link = C(153, 255, 255, 1),
	window = immutable-{background = C(24, 24, 24, .93, 'window.background'), border = C(30, 30, 30, 1, 'window.border')},
	panel = immutable-{background = C(24, 24, 24, 1, 'panel.background'), border = C(255, 255, 255, .03, 'panel.border')},
	content = immutable-{background = C(42, 42, 42, 1, 'content.background'), border = C(0, 0, 0, 0, 'content.border')},
	state = immutable-{enabled = C(70, 140, 70, 1), disabled = C(140, 70, 70, 1)},

	tooltip = immutable-{
		value = C(255, 255, 154, 1),
		merchant = C(204, 127, 25, 1),
		disenchant = immutable-{
			value = C(25, 153, 153, 1),
			distribution = C(204, 204, 51, 1),
			source = C(178, 178, 178, 1),
		}
	},

	blue = C(41, 146, 255, 1),
	green = C(22, 255, 22, 1),
	yellow = C(255, 255, 0, 1),
	orange = C(255, 146, 24, 1),
	red = C(255, 0, 0, 1),
	gray = C(187, 187, 187, 1),
	gold = C(255, 255, 154, 1),

	blizzard = C(0, 180, 255, 1),
}


-- "r,g,b,a" (0-1 floats, the format pfUI stores its colors in) -> r, g, b, a
local function parse_pfui_color(str, dr, dg, db, da)
	if type(str) ~= 'string' then return dr, dg, db, da end
	local _, _, r, g, b, a = strfind(str, '^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,?%s*([%d%.]*)')
	r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a)
	if not (r and g and b) then return dr, dg, db, da end
	return r, g, b, a or 1
end

local function set_dynamic(key, r, g, b, a)
	local list = dynamic[key]
	list[1], list[2], list[3], list[4] = floor(r * 255 + .5), floor(g * 255 + .5), floor(b * 255 + .5), a
end

-- Must run before the UI is built. Safe to call repeatedly.
function M.set_color_theme(theme)
	for key, list in dynamic do
		local d = defaults[key]
		list[1], list[2], list[3], list[4] = d[1], d[2], d[3], d[4]
	end
	if theme ~= 'pfui' then return end

	-- follow the user's pfUI colors when pfUI is installed, otherwise use pfUI's defaults
	local config = _G.pfUI_config
	local border = config and config.appearance and config.appearance.border
	local br, bg, bb, ba = parse_pfui_color(border and border.background, 0, 0, 0, 1)
	local er, eg, eb, ea = parse_pfui_color(border and border.color, .2, .2, .2, 1)
	-- pfUI draws everything with its own border background/color, so use them as they are
	set_dynamic('window.background', br, bg, bb, min(ba, .75))
	set_dynamic('window.border', er, eg, eb, ea)
	set_dynamic('panel.background', br, bg, bb, min(ba, .45))
	set_dynamic('panel.border', er, eg, eb, ea)
	set_dynamic('content.background', br, bg, bb, ba)
	set_dynamic('content.border', er, eg, eb, ea)
end
