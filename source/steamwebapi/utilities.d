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

import std.conv : to;
import std.json : JSONValue;
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

template NoNullable(T)
{
	static if (isInstanceOf!(Nullable, T))
		alias NoNullable = Unqual!(ReturnType!(T.get));
	else
		alias NoNullable = T;
}

bool isNullable(T)()
{
	return isInstanceOf!(Nullable, T);
}

T fromJSONImpl(T)(JSONValue json)
{
	static if (isBoolean!T)
		return json.boolean.to!T;
	
	else static if (isIntegral!T)
		return json.integer.to!T;
	
	else static if (isFloatingPoint!T)
		return json.floating.to!T;
	
	else static if (isSomeString!T)
		return json.str.to!T;
	
	else static if (isArray!T)
		return json.array.to!T;
	
	else static if (is(T == struct) || is(T == class))
		return T(json);
}

