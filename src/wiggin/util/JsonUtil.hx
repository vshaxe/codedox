/*
 * Copyright (C)2017 Wiggin77
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package wiggin.util;

class JsonUtil
{
	/**
	 * Returns true if the specified Dynamic object is in fact a struct (anonymous type).
	 * @param	obj - a Dynamic object
	 * @return Bool
	 */
	public static inline function isStruct(obj:Dynamic) : Bool
	{
		return (obj != null && Type.typeof(obj) == Type.ValueType.TObject && Type.getClass(obj) == null);
	}
	
	/**
	 * Returns true if the specified Dynamic object is in fact an Array.
	 * @param	obj - a Dynamic object
	 * @return Bool
	 */
	public static inline function isArray(obj:Dynamic) : Bool
	{
		return Std.is(obj, Array);
	}

	/**
	 * Converts an anonymous struct to a `Map<String,Dynamic>`.
	 * @param	obj - an anonymous struct, typically parsed from Json.
	 * @return Map<String,Dynamic>
	 */
	public static function structToMap(obj:Dynamic) : Map<String,Dynamic>
	{
		var map = new Map<String,Dynamic>();
		for (fname in Reflect.fields(obj))
		{
			map.set(fname, Reflect.field(obj, fname));
		}
		return map;
	}

} // end of JsonUtil class 