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

module steamwebapi.storeapi;

import std.conv : to;
import std.exception : enforce;
import std.json : JSONType, JSONValue, parseJSON;
import std.net.curl : get;
import std.string : format;
import std.traits : getSymbolsByUDA;
import std.typecons : nullable, Nullable;

import steamwebapi.utilities;

/**
 * Requests application details and returns received content, if any.
 *
 * Params:
 *		raw (template) = If set to `true` will return raw string response.
 *			Defaults to `false`.
 *
 * Returns:
 *		If raw flag is set to `true` than application details are returned as a
 *		JSON string.
 *		If raw is set to `false` than Nullable!AppData is returned. The result
 *		will be `null` if no application details were returned.
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
private string appDetailsImpl(bool raw : true)(const int appIDs)
{
	scope string url = "%s?appids=%d".format(
		buildStoreAPIRequestURL(StoreMethod.AppDetails),
		appIDs
	);

	return get(url).to!string;
}

/// ditto
private AppDetails appDetailsImpl(bool raw : false)(const int appIDs)
{
	scope string response = appDetails!true(appIDs);
	return AppDetails(response);
}

struct AppDetails
{
	alias _appData this;

	int steamAppID;

	private Nullable!AppData _appData;

	this(in string jsonStr)
	{
		this(jsonStr.parseJSON);
	}

	this()(auto ref JSONValue json)
	{
		// App ID is used as a json field name, but we don't know its value
		// upfront. This should be just equivalent to something like this:
		// `jsonApp = json[appID.to!string]`

		foreach (string key, ref value; json)
		{
			steamAppID = key.to!int;

			auto jsonApp = json[key];

			if (!jsonApp["success"].boolean)
				return;

			_appData = AppData(jsonApp["data"]);

			break;
		}
	}

	@property bool success() const @safe pure nothrow
	{
		return !_appData.isNull();
	}

	@property auto ref get() inout @safe pure nothrow
	{
		return _appData.get();
	}
}

/// Struct that holds all application details returned by the appDetails method.
private struct AppData
{
	@JSON("steam_appid") int  steamAppID;
	@JSON("is_free")     bool isFree;

	@JSON("type") string type;
	@JSON("name") string name;

	@JSON("detailed_description") string detailedDescription;
	@JSON("short_description")    string shortDescription;
	@JSON("about_the_game")       string aboutTheGame;

	@JSON("fullgame") Nullable!Fullgame fullgame;

	@JSON("controller_support")  string controllerSupport;
	@JSON("supported_languages") string supportedLanguages;

	@JSON("website") string website;
	@JSON("reviews") string reviews;

	@JSON("developers") string[] developers;
	@JSON("publishers") string[] publishers;

	@JSON("price_overview") Nullable!PriceOverview priceOverview;

	/// Array of the app dlcs, if any
	@JSON("dlc")            int[] dlc;
	@JSON("packages")       int[] packages;
	@JSON("package_groups") PackageGroup[]   packageGroups;

	@JSON("platforms") Platforms platforms;

	@JSON("categories")  Category[] categories;
	@JSON("genres")      Genre[]    genres;

	@JSON("movies")      Movie[] movies;
	@JSON("screenshots") Screenshot[] screenshots;

	@JSON("recommendations") Nullable!Recommendations recommendations;
	@JSON("achievements")    Nullable!Achievements    achievements;

	@JSON("release_date") ReleaseDate releaseDate;
	@JSON("support_info") SupportInfo supportInfo;

	@JSON("legal_notice") string legalNotice;
	@JSON("drm_notice")   string drmNotice;
	@JSON("metacritic")   Nullable!Metacritic metacritic;

	@JSON("header_image") string headerImage;
	@JSON("background")   string background;

	@JSON("content_descriptors") ContentDescriptors contentDescriptors;

	Nullable!Requirements pcRequirements;
	Nullable!Requirements macRequirements;
	Nullable!Requirements linuxRequirements;

	string requiredAge;

	/**
	 * Constructs AppData from json value.
	 *
	 * Params:
	 *		json = a JSONValue to build AppData from.
	 */
	this()(in auto ref JSONValue json)
	{
		serialize!AppData(this, json);

		// Steam returns required age as int if it is 0, otherwise as string
		if (json["required_age"].type == JSONType.integer)
			requiredAge = json["required_age"].integer.to!string;
		else
			requiredAge = json["required_age"].str;

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
}

struct Fullgame
{
	string appID;
	string name;

	mixin JSONCtor;
}

struct Requirements
{
	@JSON("minimum")     string minimum;
	@JSON("recommended") string recommended;

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
		serialize!PackageGroup(this, json);

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
	@JSON("highlighted") Achivement[] highlighted;

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
	@JSON("score") int score;
	@JSON("url")   string url;

	mixin JSONCtor;
}

struct ContentDescriptors
{
	@JSON("ids")   int[] ids;
	@JSON("notes") string notes;

	mixin JSONCtor;
}
