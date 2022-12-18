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

module steamwebapi.utilities;

import std.algorithm : map;
import std.array : array;
import std.conv : to;
import std.exception : basicExceptionCtors;
import std.format : format;
import std.json : JSONValue;
import std.range.primitives : ElementType;
import std.string : toLower;
import std.traits;
import std.typecons : Nullable;

/// General exception class for any Steam Web API related exceptions
class SteamWebAPIException : Exception
{
	mixin basicExceptionCtors;
}

enum Format { json, xml, vdf }

enum StoreMethod { AppDetails }

enum WebAPIInterface
{
	IPlayerService, ISteamApps, ISteamUser
}

enum WebAPIMethod
{
	GetAppList         = "GetAppList/v2",
	GetOwnedGames      = "GetOwnedGames/v1",
	GetPlayerSummaries = "GetPlayerSummaries/v2"
}

/** Base Steam Web API URL. */
enum apiURL   = "https://api.steampowered.com";

/** Base Steam Store API URL. */
enum storeURL = "https://store.steampowered.com";

string buildWebAPIRequestURL(WebAPIInterface iface, WebAPIMethod method) pure @safe
{
	return "%s/%s/%s/".format(apiURL, iface, cast(string) method);
}

string buildStoreAPIRequestURL(StoreMethod method) pure @safe
{
	return "%s/api/%s".format(storeURL, method.to!string.toLower);
}

package:

/** This attribute means that a class/struct member must be serialized. */
struct JSONAttr
{
	string key;
}

/// ditto
alias JSON = JSONAttr;

/** Simple shortcut to get JSON key name. */
enum string getJSONKey(alias R) = getUDAs!(R, JSONAttr)[0].key;

/** Returns `T` value from a given `json` regardless of its type. */
T fromJSON(T)(const auto ref JSONValue json) pure
{
	static if (isBoolean!T || isNumeric!T || isSomeString!T)
		return json.get!T();

	else static if (is(T == struct))
		return T(json);

	else static if (is(T == class))
		return new T(json);

	else static if (isArray!T)
	{
		alias elementT = ElementType!T;

		return json.array
			.map!(value => fromJSON!elementT(value))
			.array;
	}

	else
		static assert (0, "Unsupported type " ~ T.stringof);
}

///
unittest
{
	import std.json : parseJSON;

	auto json = parseJSON(`{
		"b": true,
		"i": 1,
		"s": ["str1", "str2"]
	}`);

	assert( fromJSON!bool(json["b"]) );
	assert( fromJSON!int(json["i"]) == 1 );

	assert( fromJSON!(string[])(json["s"]).length == 2 );
	assert( fromJSON!(string[])(json["s"])[0] == "str1" );
	assert( fromJSON!(string[])(json["s"])[1] == "str2" );
}

/**
 * Serializes a given struct or class from json value.
 *
 * Only members annotated with `@JSON` attribute are serialized.
 */
void serialize(T)(auto ref T val, const auto ref JSONValue json) pure
{
	import std.traits : hasUDA;

	// For some reason `getSymbolsByUDA!(T, JSONAttr)` doesn't want to work
	// with `static foreach`
	static foreach ( alias R; T.tupleof )
		static if (hasUDA!(R, JSONAttr))
		{
			static if (canBeNull!(typeof(R)))
			{
				if (getJSONKey!R in json && !json[getJSONKey!R].isNull())
					mixin(`val.` ~ R.stringof) = fromJSON!(NoNullable!(typeof(R)))(json[getJSONKey!R]);
			}
			else
				mixin(`val.` ~ R.stringof) = fromJSON!(NoNullable!(typeof(R)))(json[getJSONKey!R]);
		}
}

/** Mixin providing general constructor from a `JSONValue`. */
mixin template JSONCtor()
{
	import std.json : JSONValue;

	this()(const auto ref JSONValue json) pure
	{
		alias T = typeof(this);
		serialize!T(this, json);
	}
}

///
unittest
{
	import std.json : parseJSON;

	struct Outter {
		struct InnerS { @JSON("i") int i; mixin JSONCtor; }
		class InnerC { @JSON("f") float f; mixin JSONCtor; }

		@JSON("b") bool b;
		@JSON("str") InnerS[] str;
		@JSON("cls") InnerC cls;

		mixin JSONCtor;
	}

	enum json = parseJSON(`{
		"b": true,
		"str": [ {"i": 1}, {"i": 2} ],
		"cls": { "f": 3.3 }
	}`);

	Outter outter = Outter(json);
	assert (outter.b);
	assert (outter.str.length  == 2);
	assert (outter.str[0].i    == 1);
	assert (outter.str[1].i    == 2);
	assert (outter.cls.f       == 3.3f);
}

///
unittest
{
	// Test for errors
	import std.exception : assertNotThrown, assertThrown;
	import std.json : parseJSON;

	enum json = parseJSON(`{ "s": "Value" }`);

	// Since `json` doen not have `i` key, constructor will throw.
	struct S1 {
		@JSON("i") int i;
		mixin JSONCtor;
	}

	assertThrown(S1(json));

	// Despite none of the keys are present in JSON value, all of them can have
	// `null` value, so constructor does not throw.
	struct S2 {
		class C { @JSON("b") bool b; mixin JSONCtor; }

		@JSON("i") Nullable!int i;
		@JSON("arr") int[] arr;
		@JSON("c") C c;

		mixin JSONCtor;
	}

	assertNotThrown(S2(json));

	// Not serializible members are fine, no exception is thrown. Members that
	// are not marked with `@JSON` attribute will not be serialized.
	struct S3 {
		string s;
		mixin JSONCtor;
	}

	assertNotThrown(S3(json));
	assert( S3(json).s == "" );
}

/** Removes Nullable and all qualifiers from any given type. */
template NoNullable(T)
{
	static if (isInstanceOf!(Nullable, T))
	{
		alias baseT = ReturnType!(T.get);

		static if (isArray!baseT && !isSomeString!baseT)
		{
			alias elementT = ElementType!baseT;

			alias NoNullable = Unqual!elementT[];
		}
		else
			alias NoNullable = Unqual!baseT;
	}
	else
		alias NoNullable = Unqual!T;
}

///
unittest
{
	assert (is(NoNullable!int == int));
	assert (is(NoNullable!(Nullable!int) == int));
	assert (is(NoNullable!(Nullable!(int[])) == int[]));
	assert (is(NoNullable!(Nullable!string) == string));
	assert (is(NoNullable!(Nullable!(string[])) == string[]));
}

/** Returns `true` if `T` is instance of `Nullable`. */
enum bool isNullable(T) = isInstanceOf!(Nullable, T);

/** Returns `true` if `T` can have `null` value or is `Nullable`. */
enum bool canBeNull(T) = isNullable!T || isArray!T || is(T == class);

///
unittest
{
	class C {}
	struct S {}

	assert( canBeNull!string );
	assert( canBeNull!(int[]) );
	assert( canBeNull!C );
	assert( canBeNull!(Nullable!int) );
	assert( canBeNull!(Nullable!S) );

	assert(!canBeNull!int);
	assert(!canBeNull!S);
}
