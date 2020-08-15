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

module steamwebapi.isteamapps;

import std.algorithm : map;
import std.array : array;
import std.conv : to;
import std.json : JSONValue, parseJSON;
import std.net.curl : get;
import std.typecons : Nullable;

struct App
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

alias Game = App;

App[] GetAppList()
{
	scope auto applist = get("https://api.steampowered.com/ISteamApps/GetAppList/v2/");

	return applist
		.parseJSON["applist"]["apps"].array
		.map!(json => App(json))
		.array();
}

