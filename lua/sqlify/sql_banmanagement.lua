-- ULX SQLify System
-- thexkey and the Pootis Network Development Team
------------------
include('sqlify/sql_config.lua')
------------------

-- Overwrite The Ulib Function on a global scope
function ULib.addBan( steamid, time, reason, name, admin )
	-- No SteamID / Time, stop the script
	if steamid == nil then return end
	if time == nil then return end
	print("DBG1: "..steamid) 
	-- No Name!? Insert a false one
	if (name == nil) then
		if SQL_NoSteamName == true then
			name = SQL_BanName
		end
	end

	-- Get ban Length and add it os.time
	local BanLength = 0;
	if time == 0 then
		BanLength = 0;
	else
		BanLength = tonumber(os.time()) + (tonumber(time) * 60)
	end

	--Setup Admin Information
	local AdminName = "CONSOLE";
	local AdminSteam = "0";
	if admin != nil && admin:IsPlayer() then
		AdminName = admin:Nick()
		AdminSteam = admin:SteamID()
	end

	--Are they already banned?
	local BanStatus = ULX_DB:prepare("SELECT BanID, ban_len FROM ba_bans WHERE steamid = ? LIMIT 1;")
	local SteamID64 = util.SteamIDTo64(steamid)
	print("DBG2: "..steamid)
	print("DBG3: "..SteamID64)
	BanStatus:setString( 1, SteamID64 )
	function BanStatus.onSuccess()
		local data = BanStatus:getData()
		local row = data[1]
		PrintTable(data)
		if (#data >= 1) then -- if result is found
			if name == SQL_BanName then
				name = nil
			end
			SQL_ModifyBan(name, BanLength, reason, time, AdminName, steamid)
		end
		if (#data == 0) then
			SQL_InsertBan(steamid, name, BanLength, AdminName, AdminSteam, reason)
		end
	end
	function BanStatus.onError( err, sql ) print('[ULX SQLify] (BanStatus) - Error: ', err) end

	BanStatus:start()

	--Refresh the List!
	ULib.refreshBans()
end

function SQL_InsertBan(steamid, name, BanLength, AdminName, AdminSteam, reason)
	local nm = name
	if (nm == nil) then
		nm = 'NULL'
	end

	--Insert Ban
	-- local String = "INSERT INTO bans VALUES ('','"..steamid.."','"..SQL_Escape(name).."','"..BanLength.."','"..os.time().."',
	-- '"..SQL_Escape(AdminName).."','"..AdminSteam.."','"..SQL_Escape(reason).."','"..SQL_SERVERID.."','','"..os.time().."');"
	local String = "INSERT INTO ba_bans (steamid, ip, name, reason, a_steamid, a_name, ban_time, ban_len, unban_time, unban_reason, ServerID) VALUES (?,?,?,?,?,?,?,?,?,?,?);"

	-- if name == nil then
		-- String = "INSERT INTO bans VALUES ('','"..steamid.."',NULL,'"..BanLength.."','"..os.time().."','"..SQL_Escape(AdminName).."','"..AdminSteam.."','"..SQL_Escape(reason).."','"..SQL_SERVERID.."','','"..os.time().."');"
	-- 	name = 'NULL'
	-- end

	-- local AddBanQuery = ULX_DB:query(String)
	local AddBanQuery = ULX_DB:prepare(String)
	local SteamID64 = util.SteamIDTo64(steamid)
	AddBanQuery:setString( 1, SteamID64 ) -- todo: convert this to 64bit SteamID and have the addon read it as 32bit.
	AddBanQuery:setString( 2, "0" ) -- dummy ip, get player IP soon:tm:
	AddBanQuery:setString( 3, SQL_Escape(nm) ) -- name
	AddBanQuery:setString( 4, SQL_Escape(reason) ) -- le reason
	local AdminSteamID64 = util.SteamIDTo64(AdminSteam) -- convert admin's 32 bit steam id
 	AddBanQuery:setString( 5, AdminSteam ) -- admin's steamid64 
	AddBanQuery:setString( 6, SQL_Escape(AdminName) ) -- admin's name
	AddBanQuery:setNumber( 7, os.time() )-- time ban was created
	AddBanQuery:setNumber( 8, BanLength ) -- length of ban
	AddBanQuery:setNumber( 9, 0) -- unban_time, will be unset.
	AddBanQuery:setString( 10, "") -- unban reason, will be unset.
	AddBanQuery:setNumber( 11, SQL_SERVERID ) -- server ID
	print("DBG4: "..steamid)
	function AddBanQuery.onSuccess()
		print("[ULX SQLify] - Ban Added!");
		if name == nil then
			ULib.bans[steamid] = { unban = tonumber(BanLength), admin = AdminName, reason = reason, time = tonumber(os.time()), modified_admin = '', modified_time = tonumber(0) };
		else
			ULib.bans[steamid] = { unban = tonumber(BanLength), admin = AdminName, reason = reason,name = name, time = tonumber(os.time()), modified_admin = '', modified_time = tonumber(0) };
		end
	end

	function AddBanQuery.onError(err, sql)
		print('[ULX SQLify] (AddBanQuery) - Error: ', err)
		-- fixed so corrent mysql syntax is working
		local nm = name
		if nm == nil then
			nm = 'NULL'
		end
		-- Not Sure if the 64-bit values from before work here since they are local and this is local too.
		-- So i will just try them.
		SQL_AddTField("INSERT INTO bans (steamid, ip, name, reason, a_steamid, a_name, ban_time, ban_len, unban_time, unban_reason, ServerID) VALUES ('"..SteamID64.."','0','"..SQL_Escape(name).."','"..SQL_Escape(reason).."','"..AdminSteamID64.."','"..SQL_Escape(AdminName).."','"..os.time().."','"..BanLength.."','0','','"..SQL_SERVERID.."');")
	end
	AddBanQuery:start()

	-- Regardless of outcome Kick player From Server
	RunConsoleCommand('kickid',steamid,"You've been banned from the server ");
end

function SQL_ModifyBan(name, BanLength, reason, time, AdminName, steamid)
	--Send ban update to the Database
	-- local UpdateBanQuery = ULX_DB:query("UPDATE bans SET OName='".. SQL_Escape(name) .."', Length='".. BanLength .."', Reason='".. SQL_Escape(reason) .."',
	-- MTime='".. time .."', MAdmin='".. SQL_Escape(AdminName) .."' WHERE OSteamID='".. steamid .."';");
	
	-- updated for customDB v2
	local UpdateBanQuery = ULX_DB:prepare("UPDATE ba_bans SET name=?, ban_length=?, reason=?, WHERE steamid=?;");
	UpdateBanQuery:setString( 1, SQL_Escape(name) )
	UpdateBanQuery:setNumber( 2, BanLength )
	UpdateBanQuery:setString( 3, SQL_Escape(reason) )
	local SteamID64 = util.SteamIDTo64(steamid)
	print("DBG5: "..steamid)
	UpdateBanQuery:setString( 4, SteamID64 )
	function UpdateBanQuery.onSuccess()
		print("[ULX SQLify] - Ban Modified!");
		if name == nil then
			ULib.bans[steamid] = { unban = tonumber(BanLength), admin = AdminName, reason = reason, modified_admin = SQL_Escape(AdminName), modified_time = tonumber(time) };
		else
			ULib.bans[steamid] = { unban = tonumber(BanLength), name = name, admin = AdminName, reason = reason, modified_admin = SQL_Escape(AdminName), modified_time = tonumber(time) };
		end
	end
	function UpdateBanQuery.onError(err, sql)
		print('[ULX SQLify] (UpdateBanQuery) - Error: ', err)
		SQL_AddTField("UPDATE ba_bans SET name='".. SQL_Escape(name) .."', ban_len='".. BanLength .."', reason='".. SQL_Escape(reason) .."'..', WHERE steamid='".. SteamID64 .."';")
	end
	UpdateBanQuery:start()
end


-- Overwrite the ULib function for unbanning
function ULib.unban( steamid )
	--Query the Ban to the Database
	-- local UnBanQuery = ULX_DB:query("DELETE FROM bans WHERE OSteamID='"..steamid.."'");
	
	-- customDB v2 support
	local UnBanQuery = ULX_DB:prepare("DELETE FROM ba_bans WHERE steamid=?");
	local SteamID64 = util.SteamIDTo64(steamid)
	UnBanQuery:setString( 1, SteamID64 )
	
	function UnBanQuery.onSuccess()
		print("[ULX SQLify] - Ban Removed!");
		ULib.bans[steamid] = nil;
	end
	function UnBanQuery.onError(err, sql)
		print('[ULX SQLify] (UnBanQuery) - Error: ', err)
		SQL_AddTField("DELETE FROM ba_bans WHERE steamid='"..SteamID64.."'")
	end
	UnBanQuery:start()

	--Possible Glitch Fix, Just Incase
	-- yeah idk either
	RunConsoleCommand('removeid',steamid);

	--Refresh the List!
	ULib.refreshBans()
end


-- Refreshes the ban List
function ULib.refreshBans()

	--Use their tables ;)
	ULib.bans = nil
	ULib.bans = {}
	xgui.ulxbans = {}

	local BanList = ULX_DB:query("SELECT * FROM ba_bans ORDER BY BanID DESC")
	if !BanList then return end -- Fix Error when MySQL Server failure

	function BanList:onSuccess( data )
		for i = 1, #data do
			local LeL = util.SteamIDFrom64(data[i]['steamid'])
			
			if data[i]['name'] != nil then
				table.insert( ULib.bans, tonumber(LeL) )ULib.bans[LeL] = { unban = tonumber(data[i]['ban_len']), admin = data[i]['a_name'], reason = data[i]['reason'], name = data[i]['name'], time = tonumber(data[i]['ban_time']), modified_admin = data[i]['a_name'], modified_time = tonumber(data[i]['ban_time']) }
			else
				table.insert( ULib.bans, tonumber(LeL) )ULib.bans[LeL] = { unban = tonumber(data[i]['ban_len']), admin = data[i]['a_name'], reason = data[i]['reason'], time = tonumber(data[i]['ban_time']), modified_admin = data[i]['a_name'], modified_time = tonumber(data[i]['ban_time']) }
			end
			--^^ ULX Ban Info
			---------------------------------
			for k, v in pairs( ULib.bans ) do
				xgui.ulxbans[k] = v           -- Make sure it loads bans!
			end
			---------------------------------
			local t = {}
			t[LeL] = ULib.bans[LeL]
			xgui.addData( {}, "bans", t ) -- This will error out on startup (Most Times, GMod 13's Addon Loading is fucked), but that's fine, all ban data gets loaded already
		end

		if SQL_UsageStats then
			-- this no longer works
			--SQL_SendUsageStats(#data);
			print("Please dont use SQL_UsageStats!")
		end
	end
	function BanList.onError(err, sql) print('[ULX SQLify] (BanList) - Error: ', err) end
	BanList:start()

end
-- Refresh on Script Load -- Otherwise has issues
ULib.refreshBans()


//See if a player is banned or not and display time left.
function SQL_PlayerAuthed( ComID, IP, RealPass, ClientPass, PlayerNick )
	-- Query Bans In Descending order of banid and LIMIT 1 to obtain the latest ban
	local SteamID = SQL_ComIDtoSteamID(ComID)
	print("[ULX SQLify] AUTHING PLAYER: " .. PlayerNick .. ' WITH SteamID: ' .. SteamID)
	if ULib.bans[SteamID] then
		print('Banned')
		local BanInfo = ULib.bans[SteamID]
		local bantime = BanInfo.unban
		if bantime >= os.time() then
			local timeLeft = bantime - os.time();
			local Minutes = math.floor(timeLeft / 60);
			local Seconds = timeLeft - (Minutes * 60);
			local Hours = math.floor(Minutes / 60);
			local Minutes = Minutes - (Hours * 60);
			local Days = math.floor(Hours / 24);
			local Hours = Hours - (Days * 24);

			if (Minutes == 0 && Hours == 0 && Days == 0) then
				return false, "Banned. Lifted In: " .. Seconds + 1 .. " Seconds";
			elseif (Hours == 0 && Days == 0) then
				return false, "Banned. Lifted In: " .. Minutes + 1 .. " Minutes";
			elseif (Days == 0) then
				return false, "Banned. Lifted In: " .. Hours + 1 .. " Hours";
			else
				return false, "Banned. Lifted In: " .. Days + 1 .. " Days";
			end
		end
		if bantime == 0 then
			return false, SQL_PermaMessage;
		end
		if (bantime <= os.time() && !bantime == 0) then
			print("[ULX SQLify] - Removing expired bans!");
			ULib.unban(SteamID);
		end
	else
		print("[ULX SQLify] - User has no active bans");
	end
end
hook.Add( "CheckPassword", "CheckPassword_SQLify", SQL_PlayerAuthed )


// Timer
timer.Create( "SQL_RefreshTimer", SQL_RefreshTime, 0, function() ULib.refreshBans() end)
