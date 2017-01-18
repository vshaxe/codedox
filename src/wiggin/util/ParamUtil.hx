/*
 * Copyright (c) 2017 Wiggin77
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 * Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 * AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
 * THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package wiggin.util;

/** 
 *  Methods useful when working with parameterized fields in a template (i.e. {$myfield} )
 */
class ParamUtil
{
	/**
	 *  Applies params to a string template by replacing each `${param_name}` pattern in the
	 *  template with the corresponding value in the map.
	 *  @param strTemplate - string template containing `${param_name}` substrings
	 *  @param mapParams - map of param names and values
	 *  @return String - new string with params applied
	 */
	public static function applyParams(strTemplate:String, mapParams:Map<String,Dynamic>) : String
	{
		var mapParamsNorm = normalizeParams(mapParams);

		// Replace '${...}' fields with params.  Loop multiple times as params 
		// can have nested params.
		var bChanged = true;
		var strChanged:String;
		var regex:EReg;
		while(bChanged)
		{
			bChanged = false;
			for(key in mapParamsNorm.keys())
			{
				regex = new EReg(key, "gi");
				strChanged = regex.replace(strTemplate, mapParamsNorm.get(key));
				bChanged = bChanged || (strChanged != strTemplate);
				strTemplate = strChanged; 
			}
		}
		return strTemplate;
	}

	/**
	 *  Takes a `Map` of dynamic values and converts to a map of strings.
	 *  Also converts the keys to "${...}" fields, properly escaped for regex.
	 *
	 *  @param map - the map to convert
	 *  @return converted map
	 */
	private static function normalizeParams(params:Map<String,Dynamic>) : Map<String,String>
	{
		var map = new Map<String,String>();
		var val:Dynamic;
		var str:String;
		for(key in params.keys())
		{
			val = params.get(key);
			if(Std.is(val, Array))
			{
				var arrString:Array<String> = [];
				var arr:Array<Dynamic> = cast(val, Array<Dynamic>);
				for(elem in arr)
				{
					arrString.push(Std.string(elem));
				}
				str = arrString.join("\n");
			}
			else 
			{
				str = Std.string(val);
			}

			if(str != null && str.length > 0)
			{
				var strKeyEsc = RegExUtil.escapeRegExPattern("${" + key + "}"); 
				map.set(strKeyEsc, str);
			}
		}
		return map;
	}

	/**
	 *  Adds built-in parameters to `map`. Built-in params are things like
	 *  current year, date, time, etc. 
	 *
	 *  @param map - the map to populate.
	 */
	public static function addDefaultParams(map:Map<String,Dynamic>) : Void
	{
		var date = Date.now();

		setIfAbsent(map, "year", Std.string(date.getFullYear()));
		setIfAbsent(map, "month", Std.string(date.getMonth() + 1));
		setIfAbsent(map, "day", Std.string(date.getDate()));

		setIfAbsent(map, "timestamp", date.toString());
		setIfAbsent(map, "time24h", DateTools.format(date, "%T"));

		setIfAbsent(map, "date", DateTools.format(date, "%F"));
		setIfAbsent(map, "time", DateTools.format(date, "%l:%M:%S %p"));
	}

	/**
	 *  Utility method to set param map entries only if no mapping exists.
	 *
	 *  @param map - the map to populate
	 *  @param strKey - the key to check
	 *  @param strValue - the value to set
	 */
	public static inline function setIfAbsent(map:Map<String,Dynamic>, strKey:String, strValue:String) : Void
	{
		if(!map.exists(strKey))
		{
			map.set(strKey, strValue);
		}
	}

}