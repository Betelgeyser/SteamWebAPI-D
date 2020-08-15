/**
 * MIT License
 * Copyright (c) 2020 Sergei Filippov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

module steamwebapi.isteamuser;

import std.algorithm : map, sort, uniq;
import std.array : array, join;
import std.conv : to;
import std.json : JSONValue, parseJSON;
import std.net.curl : get;
import std.typecons : Nullable;

enum PersonaState
{
	offline        = 0,
	online         = 1,
	busy           = 2,
	away           = 3,
	snooze         = 4,
	lookingToTrade = 5,
	lookingToPlay  = 6
}

enum CommunityVisibilityState
{
	private_         = 1,
	friendsOnly      = 2,
	friendsOfFriends = 3,
	usersOnly        = 4,
	public_          = 5
}

struct Player
{
	/// Public  data
	long   steamID;
	string personaName;
	string profileURL;
	string avatar;
	string avatarMedium;
	string avatarFull;
	Nullable!int  profileState;
	Nullable!long lastLogoff;
	Nullable!int  commentPermission;
	
	PersonaState             personaState;
	CommunityVisibilityState communityVisibilityState;
	
	/// Private steam data
	Nullable!string realName;
	Nullable!long   primaryClanID;
	Nullable!long   timeCreated;
	Nullable!long   gameID;
	Nullable!string gameServerIP;
	Nullable!long   gameServerSteamID;
	Nullable!string gameExtraInfo;
	Nullable!string locCountryCode;
	Nullable!string locStateCode;
	Nullable!long   locCityCode;
	Nullable!int    personaStateFlags;
	Nullable!long   lobbySteamID;
	
	@disable this();
	
	this(JSONValue json)
	{
		steamID      = json["steamid"].str.to!long;
		personaName  = json["personaname"].str;
		profileURL   = json["profileurl"].str;
		avatar       = json["avatar"].str;
		avatarMedium = json["avatarmedium"].str;
		avatarFull   = json["avatarfull"].str;
		
		personaState             = json["personastate"].integer.to!PersonaState;
		communityVisibilityState = json["communityvisibilitystate"].integer.to!CommunityVisibilityState;
		
		if ("profilestate" in json)
			profileState = json["profilestate"].integer.to!int;
		
		if ("lastlogoff" in json)
			lastLogoff = json["lastlogoff"].integer;
		
		if ("commentpermission" in json)
			commentPermission = json["commentpermission"].integer.to!int;
		
		if ("realname" in json)
			realName = json["realname"].str;
		
		if ("primaryclanid" in json)
			primaryClanID = json["primaryclanid"].str.to!long;
		
		if ("timecreated" in json)
			timeCreated = json["timecreated"].integer;
		
		if ("gameid" in json)
			gameID = json["gameid"].str.to!long;
		
		if ("gameserverip" in json)
			gameServerIP = json["gameserverip"].str;
		
		if ("gameserversteamid" in json)
			gameServerSteamID = json["gameserversteamid"].str.to!long;
		
		if ("gameextrainfo" in json)
			gameExtraInfo = json["gameextrainfo"].str;
		
		if ("loccountrycode" in json)
			locCountryCode = json["loccountrycode"].str;
		
		if ("locstatecode" in json)
			locStateCode = json["locstatecode"].str;
		
		if ("loccitycode" in json)
			locCityCode = json["loccitycode"].integer;
		
		if ("personastateflags" in json)
			personaStateFlags = json["personastateflags"].integer.to!int;
		
		if ("lobbysteamid" in json)
			lobbySteamID = json["lobbysteamid"].str.to!long;
	}
}

Player[] GetPlayerSummaries(const string key, const long[] steamids)
{
	if (steamids.length > 100)
		throw new Exception("GetPlayerSummaries method takes only up to 100 steamids");
	
	Player[] result;
	
	scope auto response = get(
		  "https://api.steampowered.com/"
		~ "ISteamUser/GetPlayerSummaries/v2/"
		~ "?key=" ~ key
		~ "&steamids=" ~ steamids
			.sort!((a, b) => a < b) // For uniq to work properly sort is required.
			.uniq()
			.map!(x => x.to!string)
			.join(",")
	);
	
	scope auto players = response.parseJSON["response"]["players"].array;
	
	result.reserve(players.length);
	
	foreach (json; players)
		result ~= Player(json);
	
	return result;
}

