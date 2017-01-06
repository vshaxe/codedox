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

import vscode.WorkspaceConfiguration;
import wiggin.util.StructUtil;

class ConfigUtil
{
	/**
	 * 	Updates the specified `WorkspaceConfiguration` by merging the `update` struct with
	 *  the current configuration.
	 *  
	 * 	@param	update - an anonymous struct to merge with the current config
	 *  @param  ?bGlobal - if true then the global (user) config is updated, otherwise the
	 *                     workspace is updated
	 * 	@return Thenable
	 */
	public static function update(config:WorkspaceConfiguration, strSection:String, update:Dynamic, ?bGlobal=true) : js.Promise.Thenable<Void>
	{
		var curr:DynamicObject<Dynamic> = config.get(strSection, null);
		if(curr == null)
		{
			curr = {};
		}

		var merged = StructUtil.mergeStruct(curr, update);
		return config.update(strSection, merged, bGlobal);
	}

	/**
	 * 	Updates the specified `WorkspaceConfiguration` by adding any missing properties from `update`.
	 *  
	 * 	@param	update - an anonymous struct to add to the current config
	 *  @param  ?bGlobal - if true then the global (user) config is updated, otherwise the
	 *                     workspace is updated
	 * 	@return Thenable
	 */
	public static function updateIfAbsent(config:WorkspaceConfiguration, strSection:String, update:Dynamic, ?bGlobal=true) : js.Promise.Thenable<Void>
	{
		var curr:DynamicObject<Dynamic> = config.get(strSection, null);
		if(curr == null)
		{
			curr = {};
		}

		var merged = StructUtil.mergeStruct(update, curr);
		return config.update(strSection, merged, bGlobal);
	}

} // end of ConfigUtil class 

