-- ULX SQLify System
-- thexkey and the Pootis Network Development Team
------------------

//CONFIGS\\

--MySQLOO Configs for your Database
--Self explanatory
--For Best performance use a local database or under 5ms
SQL_DATABASE_HOST 		= 'localhost';
SQL_DATABASE_PORT 		= 3306;
SQL_DATABASE_NAME 		= 'db';
SQL_DATABASE_USERNAME 	= 'lol';
SQL_DATABASE_PASSWORD 	= 'lol';

--All Permanent Bans: Message you want to display to the permamently banned users who try to connect?
SQL_PermaMessage			= "You have been globally PermaBanned from Pootis, Appeal @ http://discord.gg/xPrKvt9";

--If the banner does not supply a name use a fake one instead?
SQL_NoSteamName = false;
SQL_BanName = "Console";

--Ignore this.
SQL_UsageStats = false;

--Convert all Existing ULX Bans to ULXGlobalBan Database? (First Use Only, once done please set to false and restart server!)
--Please note the converter does not always function when not all the ban data is present for that player! So please make a backup and run through the ban list to make sure that the players are there!
SQL_Convert = false;

--Should we use a timer to Refresh the ban list?
--How long should the refresh timer be? || (Each Ban / UnBan / Modification - Refreshes the BanList anyway)
SQL_RefreshTimer 		= true; -- false = No | true = Yes (DEF=true)
SQL_RefreshTime			= 30; -- Time in seconds DEF=30
