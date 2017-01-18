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

import js.Promise;
import vscode.WorkspaceConfiguration;
import wiggin.util.StructUtil;

typedef Info = {key:String, val:Dynamic, scope:Scope}

/** Simple enum for User or Workspace config scope. */
@:enum abstract Scope(String) to String
{
	var USER = "User Settings";
	var WORKSPACE = "Workspace Settings";
	var DEFAULT = "Default Settings";
	public static inline function isGlobal(scope:Scope) {return scope == Scope.USER;}
	public static inline function isWorkspace(scope:Scope) {return scope == Scope.WORKSPACE;}
	public static inline function isDefault(scope:Scope) {return scope == Scope.DEFAULT;}
}

/** 
 *  Static methods useful when dealing with `WorkspaceConfiguration` 
 *  
 */
class ConfigUtil
{
	/**
	 * 	Updates the specified `WorkspaceConfiguration` by merging the `update` struct with
	 *  the current configuration.
	 *  
	 *  @param  config - the `WorkspaceConfiguration` to update
	 *  @param  strSection - the section within the config to update
	 * 	@param	update - an anonymous struct to merge with the current config
	 *  @param  ?scope - determines where to write the update - if `Scope.USER` then global (user) config is updated, 
	 *  				 otherwise the workspace is updated
	 * 	@return Promise<Void>
	 */
	public static function update(config:WorkspaceConfiguration, strSection:String, update:Dynamic, ?scope=Scope.USER) : Promise<Void>
	{
		var prom = new Promise(function(resolve,reject) {
			var inspect = config.inspect(strSection);
			var curr:DynamicObject<Dynamic>;
			if(inspect != null)
			{
				switch(scope)
				{
					case Scope.USER:
						curr = inspect.globalValue;
					case Scope.WORKSPACE:
						curr = inspect.workspaceValue;
					case Scope.DEFAULT:
						curr = inspect.defaultValue;
					default:
						curr = {};
				}
			}
			else
			{
				curr = {};
			}

			var merged = StructUtil.mergeStruct(curr, update);
			config.update(strSection, merged, Scope.isGlobal(scope)).then(resolve,reject);
		});
		return prom;
	}

	/**
	 * 	Updates the specified `WorkspaceConfiguration` by adding any missing properties from `update`.
	 *  
	 * 	@param	update - an anonymous struct to add to the current config
	 *  @param  ?scope - determines where to write the update - if `Scope.USER` then global (user) config is updated, 
	 *  				 otherwise the workspace is updated
	 * 	@return Thenable
	 */
	public static function updateIfAbsent(config:WorkspaceConfiguration, strSection:String, update:Dynamic, ?scope=Scope.USER) : Promise<Void>
	{
		var prom = new Promise(function(resolve,reject) {
			var curr:DynamicObject<Dynamic> = config.get(strSection, null);
			if(curr == null)
			{
				curr = {};
			}
			var merged = StructUtil.mergeStruct(update, curr);
			config.update(strSection, merged, Scope.isGlobal(scope)).then(resolve,reject);
		});
		return prom;
	}

} // end of ConfigUtil class 

