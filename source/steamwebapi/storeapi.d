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

module steamwebapi.storeapi;

import std.conv : to;
import std.exception : enforce;
import std.json : JSONType, JSONValue, parseJSON;
import std.net.curl : get;
import std.traits : getSymbolsByUDA;
import std.typecons : nullable, Nullable;

import steamwebapi.utilities;

/**
 * Requests application details and returns received content, if any.
 *
 * Params:
 *		raw (template) = If set to `true` will return raw string response. Defaults to `false`.
 *
 * Returns:
 *		If raw flag is set to `true` than application details are returned as a
 *		JSON string.
 *		If raw is set to `false` than Nullable!AppData is returned. The result
 *		will be `null` if there is no application details were returned.
 */
template appDetails(bool raw = false)
{
	alias appDetails = appDetailsImpl!raw;
}

/**
 * Implements `appDetails` template.
 *
 * Params:
 *		appIDs = id of the application to get data of.
 */
private string appDetailsImpl(bool raw : true)(const uint appIDs)
{
	return get("https://store.steampowered.com/api/appdetails?appids=" ~ appIDs.to!string).to!string;
}

/// ditto
private Nullable!AppData appDetailsImpl(bool raw : false)(const uint appIDs)
{
	scope auto response = appDetails!true(appIDs);
	return AppData.fromJSONString(response);
}

/// Struct that holds all application details returned by the appDetails method.
struct AppData
{
	@JSON("steam_appid") int  steamAppID;
	@JSON("is_free")     bool isFree;
	
	@JSON("type") string type;
	@JSON("name") string name;
	
	@JSON("detailed_description") string detailedDescription;
	@JSON("short_description")    string shortDescription;
	@JSON("about_the_game")       string aboutTheGame;
	
	@JSON("fullgame") Nullable!Fullgame fullgame;
	
	@JSON("controller_support")  Nullable!string controllerSupport;
	@JSON("supported_languages") Nullable!string supportedLanguages;
	
	@JSON("website") Nullable!string website;
	@JSON("reviews") Nullable!string reviews;
	
	@JSON("developers") Nullable!(string[]) developers;
	@JSON("publishers") string[] publishers;
	
	@JSON("price_overview") Nullable!PriceOverview priceOverview;

	/// Array of the app dlcs, if any
	@JSON("dlc")            Nullable!(int[]) dlc;
	@JSON("packages")       Nullable!(int[]) packages;
	@JSON("package_groups") PackageGroup[]   packageGroups;
	
	@JSON("platforms") Platforms platforms;
	
	@JSON("categories")  Nullable!(Category[]) categories;
	@JSON("genres")      Nullable!(Genre[])    genres;
	
	@JSON("movies")      Nullable!(Movie[]) movies;
	@JSON("screenshots") Nullable!(Screenshot[]) screenshots;
	
	@JSON("recommendations") Nullable!Recommendations recommendations;
	@JSON("achievements")    Nullable!Achievements    achievements;
	
	@JSON("release_date") ReleaseDate releaseDate;
	@JSON("support_info") SupportInfo supportInfo;
	
	@JSON("legal_notice") Nullable!string legalNotice;
	@JSON("drm_notice")   Nullable!string drmNotice;
	@JSON("metacritic")   Nullable!Metacritic metacritic;
	
	@JSON("header_image") string headerImage;
	@JSON("background")   string background;
	
	@JSON("content_descriptors") ContentDescriptors contentDescriptors;
	
	Nullable!Requirements pcRequirements;
	Nullable!Requirements macRequirements;
	Nullable!Requirements linuxRequirements;
	
	int requiredAge;

	/**
	 * Constructs AppData from json value.
	 *
	 * Params:
	 *		json = a JSONValue to build AppData from.
	 */
	this(in ref JSONValue json)
	{
		fromJSON!(getSymbolsByUDA!(typeof(this), JSONAttr))(json);
		
		if (json["required_age"].type == JSONType.integer)
			requiredAge = json["required_age"].integer.to!int;
		else if (json["required_age"].type == JSONType.string)
			requiredAge = json["required_age"].str.to!int;
		
		// Generally requirements fields are returned as objects,
		// but for some reason if field is empty, steam returns
		// it as an array
		if ("pc_requirements" in json)
			if (json["pc_requirements"].type == JSONType.object)
				pcRequirements = Requirements(json["pc_requirements"]);
		
		if ("mac_requirements" in json)
			if (json["mac_requirements"].type == JSONType.object)
				macRequirements = Requirements(json["mac_requirements"]);
		
		if ("linux_requirements" in json)
			if (json["linux_requirements"].type == JSONType.object)
				linuxRequirements = Requirements(json["linux_requirements"]);
	}

	/**
	 * Constructs Nullable!AppData from a json string.
	 *
	 * Params:
	 *		str = a json formated string, most probably returned by appDetails
	 *			Steam Web API method.
	 *
	 * Returns: Nullable!AppData containing app details if the request was
	 *		successful or Nullable!AppData being null otherwise.
	 */
	static Nullable!AppData fromJSONString(in string str)
	{
		auto json = str.parseJSON;

		// Is there any other way of getting json value without knowing its key?
		// This should be just equivalent to `jsonApp = json[appID.to!string]`,
		// but we don't know the appID...
		foreach (string key, ref value; json)
		{
			auto jsonApp = json[key];
			auto appDetailsSucceded = jsonApp["success"].boolean;

			if (appDetailsSucceded)
			{
				auto result = AppData(jsonApp["data"]);
				return nullable(result);
			}
			break;
		}

		return Nullable!AppData.init;
	}
}

struct Fullgame
{
	int    appID;
	string name;

	this(JSONValue json)
	{
		appID = json["appid"].str.to!int;
		name  = json["name"].str;
	}
}

struct Requirements
{
	@JSON("minimum")     string minimum;
	@JSON("recommended") Nullable!string recommended;

	mixin JSONCtor;
}

struct PriceOverview
{
	@JSON("currency") string currency;

	@JSON("initial")  int initial;
	@JSON("final")    int final_;

	@JSON("discount_percent")  int    discountPercent;
	@JSON("initial_formatted") string initialFormatted;
	@JSON("final_formatted")   string finalFormatted;

	mixin JSONCtor;
}

struct PackageGroup
{
	@JSON("name")  string name;
	@JSON("title") string title;

	@JSON("description")    string description;
	@JSON("selection_text") string selectionText;
	@JSON("save_text")      string saveText;

	@JSON("is_recurring_subscription") string isRecurringSubscription;

	@JSON("subs") Sub[] subs;

	int displayType;

	private struct Sub
	{
		@JSON("packageid")       int packageID;
		@JSON("percent_savings") int percentSavings;

		@JSON("percent_savings_text") string percentSavingsText;
		@JSON("option_text")          string optionText;
		@JSON("option_description")   string optionDescription;
		@JSON("can_get_free_license") string canGetFreeLicense;

		@JSON("is_free_license") bool isFreeLicense;

		@JSON("price_in_cents_with_discount") int priceInCentsWithDiscount;

		mixin JSONCtor;
	}

	this(JSONValue json)
	{
		fromJSON!(getSymbolsByUDA!(typeof(this), JSONAttr))(json);

		if (json["display_type"].type == JSONType.integer)
			displayType = json["display_type"].integer.to!int;

		else if (json["display_type"].type == JSONType.string)
			displayType = json["display_type"].str.to!int;
	}
}

struct Platforms
{
	@JSON("windows") bool windows;
	@JSON("mac")     bool mac;
	@JSON("linux")   bool linux;

	mixin JSONCtor;
}

struct Category
{
	@JSON("id") int id;
	@JSON("description") string description;

	mixin JSONCtor;
}

struct Genre
{
	int    id;
	string description;

	this(JSONValue json)
	{
		if (json["id"].type == JSONType.integer)
			id = json["id"].integer.to!int;

		else if (json["id"].type == JSONType.string)
			id = json["id"].str.to!int;

		description = json["description"].str;
	}
}

struct Screenshot
{
	@JSON("id") int id;

	@JSON("path_thumbnail") string pathThumbnail;
	@JSON("path_full")      string pathFull;

	mixin JSONCtor;
}

struct Movie
{
	@JSON("id") int id;

	@JSON("name")      string name;
	@JSON("thumbnail") string thumbnail;

	@JSON("webm") Format webm;
	@JSON("mp4")  Format mp4;

	@JSON("highlight") bool highlight;

	private struct Format
	{
		@JSON("480") string _480;
		@JSON("max") string max;

		mixin JSONCtor;
	}

	mixin JSONCtor;
}

struct Recommendations
{
	@JSON("total") int total;

	mixin JSONCtor;
}

struct Achievements
{
	@JSON("total")       int total;
	@JSON("highlighted") Nullable!(Achivement[]) highlighted;

	private struct Achivement
	{
		@JSON("name") string name;
		@JSON("path") string path;

		mixin JSONCtor;
	}

	mixin JSONCtor;
}

struct ReleaseDate
{
	@JSON("coming_soon") bool comingSoon;
	@JSON("date")        string date;

	mixin JSONCtor;
}

struct SupportInfo
{
	@JSON("url")   string url;
	@JSON("email") string email;

	mixin JSONCtor;
}

struct Metacritic
{
	@JSON("score") int    score;
	@JSON("url")   Nullable!string url;

	mixin JSONCtor;
}

struct ContentDescriptors
{
	@JSON("ids")   int[] ids;
	@JSON("notes") Nullable!string notes;

	mixin JSONCtor;
}