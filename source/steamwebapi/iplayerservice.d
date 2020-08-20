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

module steamwebapi.iplayerservice;

import std.algorithm : map, sort, uniq;
import std.array : array, join;
import std.conv : to;
import std.json : JSONValue, parseJSON;
import std.net.curl : get;
import std.typecons : Nullable;

struct OwnedGame
{
	uint appID;
	
	string name;
	string imgIconURL;
	string imgLogoURL;
	
	Nullable!uint playtime2weeks;
	Nullable!uint playtimeForever;
	Nullable!uint playtimeWindowsForever;
	Nullable!uint playtimeMacForever;
	Nullable!uint playtimeLinuxForever;
	
	@disable this();
	
	this(JSONValue json)
	{
		appID = json["appid"].integer.to!uint;
		
		if ("name" in json)
			name = json["name"].str;
		
		if ("img_icon_url" in json)
			imgIconURL = json["img_icon_url"].str;
		
		if ("img_logo_url" in json)
			imgLogoURL = json["img_logo_url"].str;
		
		if ("playtime_2weeks" in json)
			playtime2weeks = json["playtime_2weeks"].integer.to!uint;
		
		if ("playtime_forever" in json)
			playtimeForever = json["playtime_forever"].integer.to!uint;
		
		if ("playtime_windows_forever" in json)
			playtimeWindowsForever = json["playtime_windows_forever"].integer.to!uint;
		
		if ("playtime_mac_forever" in json)
			playtimeMacForever = json["playtime_mac_forever"].integer.to!uint;
		
		if ("playtime_linux_forever" in json)
			playtimeLinuxForever = json["playtime_linux_forever"].integer.to!uint;
	}
}

OwnedGame[] GetOwnedGames(const string key, const long steamid, const bool includeAppInfo = false, const bool includePlayedFreeGames = false, const uint[] appidsFilter = null)
{
	scope JSONValue parameters;
	parameters["steamid"] = JSONValue(steamid);
	
	if (includeAppInfo)
		parameters["include_appinfo"] = JSONValue(1);
	
	if (includePlayedFreeGames)
		parameters["include_played_free_games"] = JSONValue(1);
	
	if (appidsFilter !is null)
		parameters["appids_filter"] = JSONValue(appidsFilter);
	
	scope auto response = get(
		  "https://api.steampowered.com/"
		~ "IPlayerService/GetOwnedGames/v1/"
		~ "?key=" ~ key
		~ "&format=json"
		~ "&input_json=" ~ parameters.toString
	);
	
	scope auto json = response.parseJSON;
	
	auto result = json["response"]["games"]
		.array()
		.map!(json => OwnedGame(json))
		.array();
	
	assert (result.length == json["response"]["game_count"].integer());
	
	return result;
}
