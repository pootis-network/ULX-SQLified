-- ULX SQLify System
-- thexkey and the Pootis Network Development Team
------------------

//Require MySQLOO
local MySQLOO = require( 'mysqloo' )
require( 'mysqloo' )

//Include Globals
include('sql_config.lua')

//Setup Fail QueryLine Ups
ULX_SQL_F = {}

//Setup MySQLOO Connections
ULX_DB = mysqloo.connect(SQL_DATABASE_HOST, SQL_DATABASE_USERNAME, SQL_DATABASE_PASSWORD, SQL_DATABASE_NAME, SQL_DATABASE_PORT)

include( 'sql_serverheartbeat.lua' );

function SQL_RemoveTField(ID)
	table.remove( ULX_SQL_F, ID )
end

function SQL_AddTField(Query)
	table.insert(ULX_SQL_F, Query)
end

local function RedoQueries()
	for i = 1, #ULX_SQL_F do
		local RedoQueries = ULX_DB:query(ULX_SQL_F[i])
		RedoQueries.onSuccess = function()
			print('[ULX SQLify] Successfully Completed Query: ' .. ULX_SQL_F[i]);
			SQL_RemoveTField(i);
		end
		RedoQueries.onError = function(db, err) print('[ULX SQLify] (RedoQueries) - Error: ', err) end
		RedoQueries:start()
	end
end

function afterConnected(database)
	print('[ULX SQLify] - Database Connection Successful ' )

	--Check Wether or not a server exists in the Database
	SQL_QueryDatabaseForServer()

	--Dam ULib Fails when inclduing this anywhere else...
	if (SQL_Convert == true) then
		include('sqlify/sql_convert.lua')
	else
		include('sqlify/sql_banmanagement.lua')
	end

	RedoQueries()
end

function connectToDatabase()
	print('[ULX SQLify] - Connecting to Database!')

	ULX_DB.onConnected = afterConnected
	ULX_DB.onConnectionFailed = function(db, msg) print("[ULX SQLify] connectToDatabase") print(msg) end
	ULX_DB:connect()
end

//Run the connection!
connectToDatabase()

//Keep the MySQL Database Open and Connected.
local function DbCheck()
	if (ULX_DB:status() != mysqloo.DATABASE_CONNECTED) then
		connectToDatabase();
		print('[ULX SQLify] - Database Connection Restarted' )
	end
end
timer.Create( 'DbCheck', 90, 0, DbCheck )
