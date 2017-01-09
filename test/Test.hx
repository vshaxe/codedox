/*
 * Copyright (c) 2017 Noah
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/

package ;

class Test
{
	private var m_strToken:String;

	public static function main()
	{
		trace(getMessage("Hello", 2));
	}

	private static function getMessage(str:String, num:Int) : String
	{
		return "message: " + str + num;
	}
	@MyAnnot("Hi there")
	private static function populateMap(map:Map<String,String>, strMsg:String="Hi, there!") : Void
	{
		for(i in 1...10)
		{
			map.set(Std.string(i), strMsg + " -- " + Std.string(i + 100));
		}
	}
}

