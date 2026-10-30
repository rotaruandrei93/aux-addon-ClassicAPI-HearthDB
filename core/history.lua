module 'aux.core.history'


--not using acecomm anymore
--[[AuxAddon = AceLibrary("AceAddon-2.0"):new("AceComm-2.0")   --im unsure this is done correctly but seems to work lol

local commPrefix = "AuxAddon";
AuxAddon:SetCommPrefix(commPrefix)

function AuxAddon:OnEnable()
	--self:RegisterComm(commPrefix, "GROUP", "OnCommReceive"); --for testing purposes, not really useful in real world I think
	self:RegisterComm(commPrefix, "GUILD", "OnCommReceive");
	--self:RegisterComm(commPrefix, "ZONE", "OnCommReceive");
end ]]--

local T = require 'T'
local aux = require 'aux'

local persistence = require 'aux.util.persistence'

local history_schema = {'tuple', '#', {next_push='number'}, {daily_min_buyout='number'}, {data_points={'list', ';', {'tuple', '@', {value='number'}, {time='number'}}}}}

local value_cache = {}
local daily_min_cache = {}
local daily_min_cache_until = 0

--[[
	Price history storage.

	With the HearthDB plugin (HearthDB.dll) installed, history lives in a SQLite database
	(CustomData/aux-history.db): reads are served from a small in-memory cache, writes are batched and sent
	to HearthDB's background thread, so a big scan no longer rewrites a huge SavedVariables table.
	Without HearthDB everything behaves exactly like before (SavedVariables).
	Records keep the same serialized format in both places, so the price logic is untouched.
]]
local DB_FILE = 'aux-history.db'
local FLUSH_DELAY = 3       -- seconds writes are collected before they are sent to the database
local FLUSH_MAX_ROWS = 300  -- rows per background write
local MIGRATE_ROWS = 100    -- legacy rows copied per step
local db                    -- HearthDB handle (nil: HearthDB missing or failed, SavedVariables are used)
local scope                 -- 'realm|faction', same key SavedVariables use
local raw_cache = {}        -- item_key -> serialized record (false: known to be missing)
local pending, pending_count = {}, 0
local flush_scheduled

local function sql_escape(str)
	return (gsub(str, "'", "''"))
end

local function hdb_installed()
	return HDB_Open and HDB_Query and HDB_Execute and HDB_ExecuteAsync and true or false
end

local function db_failed(reason, batch)
	if not db then return end
	aux.print(aux.color.orange('HearthDB problem, price history uses SavedVariables until you reload: ' .. tostring(reason)))
	-- never lose data: whatever was not written yet goes to SavedVariables
	if batch then
		for item_key, str in batch do data[item_key] = str end
	end
	for item_key, str in pending do
		data[item_key] = str
		pending[item_key] = nil
	end
	pending_count = 0
	db = nil
end

local function open_db()
	if not hdb_installed() then return end
	local ok, handle = pcall(HDB_Open, DB_FILE)
	if not ok then
		aux.print(aux.color.orange('HearthDB could not open ' .. DB_FILE .. ': ' .. tostring(handle)))
		return
	end
	local created, err = pcall(HDB_Execute, handle, [[CREATE TABLE IF NOT EXISTS history (
		scope TEXT NOT NULL,
		item_key TEXT NOT NULL,
		data TEXT NOT NULL,
		PRIMARY KEY (scope, item_key)
	) WITHOUT ROWID]])
	if not created then
		pcall(HDB_Close, handle)
		aux.print(aux.color.orange('HearthDB could not prepare ' .. DB_FILE .. ': ' .. tostring(err)))
		return
	end
	db = handle
end

local function get_raw(item_key)
	if not db then return data[item_key] end
	local cached = raw_cache[item_key]
	if cached ~= nil then return cached or nil end
	local value
	local ok, rows = pcall(HDB_Query, db, format("SELECT data FROM history WHERE scope='%s' AND item_key='%s'", sql_escape(scope), sql_escape(item_key)))
	if ok then
		value = rows and rows[1] and rows[1].data
	else
		db_failed(rows)
	end
	-- not copied to the database yet? then it is still in the old SavedVariables table
	if value == nil then value = data[item_key] end
	if db then raw_cache[item_key] = value or false end
	return value
end

-- sync: write everything now (logout, closing the auction house). Otherwise a limited batch goes to the background thread.
local function flush(sync)
	if not db or pending_count == 0 then return end
	local statements, batch, n = {'BEGIN;'}, {}, 0
	for item_key, str in pending do
		tinsert(statements, format("INSERT OR REPLACE INTO history VALUES ('%s','%s','%s');", sql_escape(scope), sql_escape(item_key), sql_escape(str)))
		batch[item_key] = str
		pending[item_key] = nil
		pending_count = pending_count - 1
		n = n + 1
		if not sync and n >= FLUSH_MAX_ROWS then break end
	end
	tinsert(statements, 'COMMIT;')
	local sql = table.concat(statements)
	if sync then
		local ok, err = pcall(HDB_Execute, db, sql)
		if not ok then
			pcall(HDB_Execute, db, 'ROLLBACK')
			db_failed(err, batch)
		end
	else
		local ok, err = pcall(HDB_ExecuteAsync, db, sql, function(_, write_error)
			if write_error then
				pcall(HDB_ClearPoison, db)
				pcall(HDB_Execute, db, 'ROLLBACK') -- harmless when no transaction is open
				db_failed(write_error, batch)
			end
		end)
		if not ok then db_failed(err, batch) end
		if pending_count > 0 then schedule_flush() end
	end
end

function schedule_flush()
	if flush_scheduled then return end
	flush_scheduled = true
	aux.thread(aux.when, aux.later(FLUSH_DELAY), function()
		flush_scheduled = nil
		flush()
	end)
end

local function put_raw(item_key, str)
	if not db then
		data[item_key] = str
		return
	end
	raw_cache[item_key] = str
	if pending[item_key] == nil then pending_count = pending_count + 1 end
	pending[item_key] = str
	schedule_flush()
end

-- Copies the old SavedVariables history into the database, a few rows per step so the game never stalls.
-- Existing database rows win (INSERT OR IGNORE), so this is safe to repeat.
local function start_migration()
	if not db or aux.faction_data.history_migrated then return end
	local keys = {}
	for item_key in data do tinsert(keys, item_key) end
	local total = getn(keys)
	local function finish()
		local ok, rows = pcall(HDB_Query, db, format("SELECT COUNT(*) AS n FROM history WHERE scope='%s'", sql_escape(scope)))
		if ok and rows and rows[1] and (tonumber(rows[1].n) or 0) >= total then
			aux.faction_data.history_migrated = true
			if total > 0 then
				aux.print('price history of ' .. total .. ' items copied to HearthDB. Type ' .. aux.color.blue'/aux hdb clean' .. ' to remove the old copy from SavedVariables.')
			end
		end
	end
	local function step(index)
		if not db then return end
		local statements, n = {'BEGIN;'}, 0
		while index <= total and n < MIGRATE_ROWS do
			local item_key = keys[index]
			local str = data[item_key]
			if str then
				tinsert(statements, format("INSERT OR IGNORE INTO history VALUES ('%s','%s','%s');", sql_escape(scope), sql_escape(item_key), sql_escape(str)))
				n = n + 1
			end
			index = index + 1
		end
		tinsert(statements, 'COMMIT;')
		if n > 0 then
			local ok, err = pcall(HDB_ExecuteAsync, db, table.concat(statements), function(_, write_error)
				if write_error then
					pcall(HDB_ClearPoison, db)
					pcall(HDB_Execute, db, 'ROLLBACK')
				end
			end)
			if not ok then return end
		end
		if index <= total then
			return aux.when(aux.later(.25), step, index)
		else
			return aux.when(aux.later(3), finish)
		end
	end
	if total == 0 then
		aux.faction_data.history_migrated = true
		return
	end
	aux.thread(step, 1)
end

function aux.handle.LOAD2()
	data = aux.faction_data.history
	do
		local realm = GetCVar'realmName'
		scope = format('%s|%s', realm, realm == 'Nordanaar' and 'Horde' or UnitFactionGroup'player') -- same key as aux.faction
	end
	open_db()
	start_migration()
	local _, name = GetChannelName("LFT")
	if aux.account_data.sharing and not name then
		aux.thread(aux.when, aux.later(5), function()
			local shouldJoin = true
			for i, channel in ipairs({GetChannelList()}) do
				if channel == "LFT" then
					shouldJoin = false
					break
				end
			end
			if shouldJoin then
				JoinChannelByName("LFT")
			end
		end)
	end
end

function aux.handle.CLOSE()
	for item_key in daily_min_cache do
		daily_min_cache[item_key] = nil
	end
	daily_min_cache_until = 0
	flush(true)
end

do
	local logout_frame = CreateFrame('Frame', 'aux_history_logout')
	logout_frame:RegisterEvent('PLAYER_LOGOUT')
	logout_frame:SetScript('OnEvent', function() flush(true) end)
end

do
	local next_push = 0
	function get_next_push()
		if time() > next_push then
			local date = date('*t')
			date.hour, date.min, date.sec = 24, 0, 0
			next_push = time(date)
		end
		return next_push
	end
end

function refresh_daily_min_cache(now)
	if now >= daily_min_cache_until then
		for item_key in daily_min_cache do
			daily_min_cache[item_key] = nil
		end
		daily_min_cache_until = get_next_push()
	end
end

function new_record()
	return T.temp-T.map('next_push', get_next_push(), 'data_points', T.acquire())
end

function read_record(item_key)
	local raw = get_raw(item_key)
	local record = raw and persistence.read(history_schema, raw) or new_record()
	if record.next_push <= time() then
		push_record(record)
		write_record(item_key, record)
	end
	return record
end

function write_record(item_key, record)
	put_raw(item_key, persistence.write(history_schema, record))
	daily_min_cache[item_key] = record.daily_min_buyout or false
	if value_cache[item_key] then
		T.release(value_cache[item_key])
		value_cache[item_key] = nil
	end
end

local data_sharer = CreateFrame("Frame", "aux_data_sharer")
data_sharer:RegisterEvent("CHAT_MSG_CHANNEL")

data_sharer:SetScript("OnEvent", function()
	if not aux.account_data.sharing then return end
	if strupper(arg9 or "") ~= "LFT" then return end

	local message = arg1 or ""
	if strsub(message, 1, 8) ~= "AuxData," then return end
	if arg2 == UnitName("player") then return end

	local _, _, item_key, munit_buyout_price = strfind(message, "^AuxData,([^,]+),([^,]+)$") -- using , as a separator because item_key contains a :
	if not item_key then return end

	local unit_buyout_price = tonumber(munit_buyout_price) or 0
	if unit_buyout_price <= 0 then return end

	local now = time()
	refresh_daily_min_cache(now)

	local cached_min = daily_min_cache[item_key]
	if cached_min and unit_buyout_price >= cached_min then
		return
	end

	local item_record = read_record(item_key)
	local daily_min_buyout = item_record.daily_min_buyout
	daily_min_cache[item_key] = daily_min_buyout or false

	if unit_buyout_price < (daily_min_buyout or aux.huge) then
		item_record.daily_min_buyout = unit_buyout_price
		write_record(item_key, item_record)
	end
	-- print(arg1)
end)

function M.process_auction(auction_record, pages)
	if auction_record.buyout_price <= 0 then return end

	local item_key = auction_record.item_key
	local unit_buyout_price = ceil(auction_record.buyout_price / auction_record.aux_quantity)
	local now = time()
	refresh_daily_min_cache(now)

	local cached_min = daily_min_cache[item_key]
	if cached_min and unit_buyout_price >= cached_min then
		return
	end

	local item_record = read_record(item_key)
	local daily_min_buyout = item_record.daily_min_buyout
	daily_min_cache[item_key] = daily_min_buyout or false

	if unit_buyout_price < (daily_min_buyout or aux.huge) then
		item_record.daily_min_buyout = unit_buyout_price
		write_record(item_key, item_record)
		--AuxAddon:SendCommMessage("GUILD", item_key, unit_buyout_price) relies on acecomm
		if aux.account_data.sharing then
			if (tonumber(pages) or 0) < 15 then --to avoid sharing data when people do searches without a keyword "full scans"
				local channel_id = GetChannelName("LFT")
				if channel_id and channel_id ~= 0 then
					ChatThrottleLib:SendChatMessage("BULK", nil, "AuxData," .. item_key .."," .. unit_buyout_price , "CHANNEL", nil, channel_id) --ChatThrottleLib fixed for turtle by Candor https://github.com/trumpetx/ChatLootBidder/blob/master/ChatThrottleLib.lua
				  	--print("sent")
				end
		 	end
		end
	end
end

--[[ function AuxAddon:OnCommReceive(prefix, sender, distribution, item_key, unit_buyout_price) --copied code from process_auction. <- code for when using acecomm
	print("received data"); --for testing (print comes from PFUI)
	local item_record = read_record(item_key)
	if unit_buyout_price > 0 and unit_buyout_price < (item_record.daily_min_buyout or aux.huge) then
		item_record.daily_min_buyout = unit_buyout_price
		write_record(item_key, item_record)
		--print("wrote data"); --for testing (print comes from PFUI)
	end
end ]]--

function M.data_points(item_key)
	return read_record(item_key).data_points
end

function M.value(item_key)
	local now = time()
	if not value_cache[item_key] or value_cache[item_key].next_push <= now then
		local item_record, value
		item_record = read_record(item_key)
		if getn(item_record.data_points) > 0 then
			local total_weight, weighted_values = 0, T.temp-T.acquire()
			local newest_time = item_record.data_points[1].time
			for _, data_point in item_record.data_points do
				local weight = .99 ^ aux.round((newest_time - data_point.time) / (60 * 60 * 24))
				total_weight = total_weight + weight
				data_point.weight = weight
				tinsert(weighted_values, data_point)
			end
			value = weighted_median(weighted_values, total_weight * .5)
		else
			value = item_record.daily_min_buyout
		end
		value_cache[item_key] = T.map('value', value, 'next_push', item_record.next_push)
	end
	return value_cache[item_key].value
end

function M.market_value(item_key)
	return read_record(item_key).daily_min_buyout
end

function weighted_median(list, target_weight)
	sort(list, function(a,b) return a.value < b.value end)
	local weight = 0
	for _, v in ipairs(list) do
		weight = weight + v.weight
		if weight >= target_weight then
			return v.value
		end
	end
end

function push_record(item_record)
	if item_record.daily_min_buyout then
		tinsert(item_record.data_points, 1, T.map('value', item_record.daily_min_buyout, 'time', item_record.next_push))
		while getn(item_record.data_points) > 11 do
			T.release(item_record.data_points[getn(item_record.data_points)])
			tremove(item_record.data_points)
		end
	end
	item_record.next_push, item_record.daily_min_buyout = get_next_push(), nil
end


function M.hdb_report()
	local legacy_count = 0
	for _ in data or {} do legacy_count = legacy_count + 1 end
	if not hdb_installed() then
		aux.print('HearthDB: ' .. aux.color.red'not found' .. ' - price history stays in SavedVariables (' .. legacy_count .. ' items). Put HearthDB.dll next to WoW.exe to enable it.')
		return
	end
	local major, minor, patch = HDB_GetVersion()
	if not db then
		aux.print('HearthDB ' .. major .. '.' .. minor .. '.' .. patch .. ': ' .. aux.color.red'not in use' .. ' (database could not be opened) - price history stays in SavedVariables (' .. legacy_count .. ' items).')
		return
	end
	local rows = 0
	local ok, result = pcall(HDB_Query, db, format("SELECT COUNT(*) AS n FROM history WHERE scope='%s'", sql_escape(scope)))
	if ok and result and result[1] then rows = tonumber(result[1].n) or 0 end
	aux.print('HearthDB ' .. major .. '.' .. minor .. '.' .. patch .. ': ' .. aux.color.green'active' .. ' - ' .. rows .. ' items in CustomData/' .. DB_FILE
		.. ', ' .. legacy_count .. ' items left in SavedVariables' .. (aux.faction_data.history_migrated and '' or ' (copy still running)'))
end

function M.hdb_clean()
	if not db then
		aux.print('HearthDB is not in use, nothing was removed.')
		return
	end
	if not aux.faction_data.history_migrated then
		aux.print('The copy to HearthDB is not finished yet. Try again in a minute.')
		return
	end
	flush(true)
	local removed = 0
	for item_key in data do
		data[item_key] = nil
		removed = removed + 1
	end
	aux.print('removed ' .. removed .. ' old price history items from SavedVariables (they are in HearthDB).')
end
