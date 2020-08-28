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

module steamwebapi.utilities;

import std.algorithm : map;
import std.array : array;
import std.conv : to;
import std.json : JSONValue;
import std.range.primitives : ElementType;
import std.traits;
import std.typecons : Nullable;

struct JSONAttr
{
	string key;
}

alias JSON = JSONAttr;

mixin template JSONCtor()
{
	import std.json : JSONValue;
	this(JSONValue json)
	{
		import std.traits : getSymbolsByUDA;
		fromJSON!(getSymbolsByUDA!(typeof(this), JSONAttr))(json);
	}
}

void fromJSON(args...)(JSONValue json)
{
	static if (args.length > 0)
	{
		immutable key = getUDAs!(args[0], JSONAttr)[0].key;
		
		alias T = typeof(args[0]);
		
		static if (isNullable!T)
		{
			alias baseT = NoNullable!T;
			
			if (key in json)
				if (!json[key].isNull)
					args[0] = fromJSONImpl!baseT(json[key]);
		}
		else
		{
			args[0] = fromJSONImpl!T(json[key]);
		}
		
		fromJSON!(args[1..$])(json);
	}
}

package:

/**
 * Removes Nullable and all qualifiers from any given type.
 */
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

/**
 * Returns `true` if T is instance of Nullable.
 */
bool isNullable(T)()
{
	return isInstanceOf!(Nullable, T);
}

T fromJSONImpl(T)(JSONValue json)
{
	static if (isBoolean!T || isNumeric!T || isSomeString!T)
		return json.get!T;
	
	else static if (is(T == struct) || is(T == class))
		return T(json);
	
	else static if (isArray!T)
	{
		alias elementT = ElementType!T;
		
		return json.array
			.map!(value => fromJSONImpl!elementT(value))
			.array.to!T;
	}

	else
		static assert (0, "Unsupported type " ~ T.stringof);
}

unittest
{
	import std.json : parseJSON;
	
	struct Outter
	{
		bool b;
		string[] arr;
		Inner[] inner;
		
		struct Inner
		{
			int i;
			float f;
			
			this(JSONValue json)
			{
				i = fromJSONImpl!int(json["i"]);
				f = fromJSONImpl!float(json["f"]);
			}
		}
		
		this(JSONValue json)
		{
			b     = fromJSONImpl!bool(json["b"]);
			arr   = fromJSONImpl!(string[])(json["arr"]);
			inner = fromJSONImpl!(Inner[])(json["inner"]);
		}
	}
	
	string str = "{
		\"b\": true,
		\"arr\": [\"Some string\", \"Some other string\"],
		\"inner\": [
			{
				\"i\": 1,
				\"f\": 1.1
			},
			{
				\"i\": 2,
				\"f\": 2.2
			}
		]
	}";
	
	auto json = parseJSON(str);
	Outter outter = Outter(json);
	
	assert (outter.b);
	assert (outter.arr == ["Some string", "Some other string"]);
	
	assert (outter.inner.length == 2);
	assert (outter.inner[0].i   == 1);
	assert (outter.inner[0].f   == 1.1f);
	assert (outter.inner[1].i   == 2);
	assert (outter.inner[1].f   == 2.2f);
}
