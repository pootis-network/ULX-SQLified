-- ULX SQLify System
-- thexkey and the Pootis Network Development Team
------------------

-- Global Value; can be used in any other supported scripts.
SQL_SERVERID = 0

local function GetServerIP()
  local hostip = GetConVarString( "hostip" )
  hostip = tonumber( hostip )

  local ip = {}
  ip[ 1 ] = bit.rshift( bit.band( hostip, 0xFF000000 ), 24 )
  ip[ 2 ] = bit.rshift( bit.band( hostip, 0x00FF0000 ), 16 )
  ip[ 3 ] = bit.rshift( bit.band( hostip, 0x0000FF00 ), 8 )
  ip[ 4 ] = bit.band( hostip, 0x000000FF )

  return table.concat( ip, "." )
end


function SQL_QueryDatabaseForServer()
	--Gather Identification Infos
	local HostName = SQL_Escape(GetHostName());
	local IPAddress = GetServerIP();
	local HostPort = GetConVarString("hostport");

	-- Setting up the Query
	local HeartbeatQuery = ULX_DB:query("SELECT ServerID FROM servers WHERE IPAddress ='"..IPAddress.."' AND Port = '"..HostPort.."'");
  -- local HeartbeatQuery = ULX_DB:prepare("SELECT ServerID FROM servers WHERE IPAddress = ? AND Port = ?");
	function HeartbeatQuery:onSuccess( data )
		local row = data[1]
		-- Query The Database to see if server exists and retrieve the Server's ID
		if (#data == 0) then
			-- If Database does not have IP and port create a new row and populate it accordingly
			print("[ULX SQLify] - Server not present, creating...");
			SQL_InsertNewServer()
		elseif (#data == 1) then
			-- There should be only one entry
			SQL_SERVERID = tonumber(row['ServerID']);
			SQL_UpdateServerName();
			print("[ULX SQLify] - ServerID Set To: ".. SQL_SERVERID);
		else
			print("[ULX SQLify] (UpdateName) - Error: Multiple entries found for IPAddress "..IPAddress.." and Port "..HostPort)
		end
	end
	HeartbeatQuery.onError = function(db, err) print('[ULX SQLify] (HeartbeatQuery) - Error: ', err) end
	HeartbeatQuery:start()

end

function SQL_UpdateServerName()
	--Gather Identification Infos
	local HostName = SQL_Escape(GetHostName());

  -- local UpdateName = ULX_DB:query(" UPDATE servers SET HostName='".. HostName .."' WHERE ServerID='"..SQL_SERVERID.."' ");
  local UpdateName = ULX_DB:prepare(" UPDATE servers SET HostName=? WHERE ServerID=?");
  UpdateName:setString( 1, HostName )
  UpdateName:setNumber( 2, SQL_SERVERID )
	function UpdateName:onSuccess()
		print("[ULX SQLify] - Updated HostName Successfully!");
	end
	function UpdateName:onError( err, sql ) print('[ULX SQLify] (UpdateName) - Error: ', err) end
	UpdateName:start()

end

function SQL_InsertNewServer()
	--Gather Indentification Infos
	local HostName = SQL_Escape(GetHostName());
	local IPAddress = GetServerIP();
	local HostPort = GetConVarString("hostport");

	-- local NewServer = ULX_DB:query("INSERT INTO servers (IPAddress, Port, HostName) VALUES ("..IPAddress.."','"..HostPort.."','"..HostName.."')");
  local NewServer = ULX_DB:prepare("INSERT INTO servers (IPAddress, Port, HostName) VALUES (?,?,?)")
  NewServer:setString( 1, IPAddress )
  NewServer:setString( 2, HostPort )
  NewServer:setString( 3, HostName )
  function NewServer:onSuccess( data )
		print("[ULX SQLify] - Inserted New Server!");
		SQL_QueryDatabaseForServer()
	end
	function NewServer:onError(err)
		print('[ULX SQLify] (NewServer) - Error: ', err);
		SQL_QueryDatabaseForServer()
	end

	NewServer:start()

end
