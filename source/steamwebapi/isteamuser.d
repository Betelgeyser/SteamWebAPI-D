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
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
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
import std.json : parseJSON;
import std.net.curl : get;
import std.typecons : Nullable;

import steamwebapi.utilities;

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
	private_    = 1,
	friendsOnly = 2,
	public_     = 3
}

struct Player
{
	/// Public data
	@JSON("steamid")     string steamID;
	@JSON("personaname") string personaName;
	@JSON("profileurl")  string profileURL;

	@JSON("avatar")       string avatar;
	@JSON("avatarmedium") string avatarMedium;
	@JSON("avatarfull")   string avatarFull;

	@JSON("profilestate") Nullable!int  profileState;
	@JSON("lastlogoff")   Nullable!long lastLogoff;

	@JSON("commentpermission") Nullable!int commentPermission;

	@JSON("personastate") PersonaState personaState;
	@JSON("communityvisibilitystate") CommunityVisibilityState communityVisibilityState;

	/// Private steam data
	@JSON("realname")          string realName;
	@JSON("timecreated")       Nullable!long   timeCreated;
	@JSON("gameserverip")      string gameServerIP;
	@JSON("gameextrainfo")     string gameExtraInfo;
	@JSON("loccountrycode")    string locCountryCode;
	@JSON("locstatecode")      string locStateCode;
	@JSON("loccitycode")       Nullable!long   locCityCode;
	@JSON("personastateflags") Nullable!int personaStateFlags;

	@JSON("primaryclanid")     string primaryClanID;
	@JSON("gameid")            string gameID;
	@JSON("gameserversteamid") string gameServerSteamID;
	@JSON("lobbysteamid")      string lobbySteamID;

	mixin JSONCtor;
}

Player[] getPlayerSummaries(const string key, const long[] steamids)
{
	if (steamids.length > 100)
		throw new Exception("GetPlayerSummaries method takes only up to 100 steamids");

	scope auto response = get(
		  "https://api.steampowered.com/"
		~ "ISteamUser/GetPlayerSummaries/v2/"
		~ "?key=" ~ key
		~ "&steamids=" ~ steamids
			.dup()
			.sort!((a, b) => a < b) // uniq works on consecutive elements only.
			.uniq()
			.map!(id => id.to!string)
			.join(",")
	);

	return response
		.parseJSON["response"]["players"].array
		.map!(json => Player(json))
		.array;
}
