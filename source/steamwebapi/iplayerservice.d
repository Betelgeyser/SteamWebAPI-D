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

module steamwebapi.iplayerservice;

import std.algorithm : map;
import std.array : array;
import std.json : JSONValue, parseJSON;
import std.net.curl : get;
import std.typecons : Nullable;

import steamwebapi.utilities;

struct OwnedGame
{
	@JSON("appid") int appID;

	@JSON("name") string name;
	@JSON("img_icon_url") string imgIconURL;
	@JSON("img_logo_url") string imgLogoURL;

	@JSON("playtime_2weeks")  Nullable!int playtime2weeks;
	@JSON("playtime_forever") Nullable!int playtimeForever;
	@JSON("playtime_windows_forever") Nullable!int playtimeWindowsForever;
	@JSON("playtime_mac_forever")     Nullable!int playtimeMacForever;
	@JSON("playtime_linux_forever")   Nullable!int playtimeLinuxForever;

	mixin JSONCtor;
}

OwnedGame[] getOwnedGames(const string key, const long steamid, const bool includeAppInfo = false,
                          const bool includePlayedFreeGames = false, const uint[] appidsFilter = null)
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
