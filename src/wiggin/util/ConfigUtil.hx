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

class ConfigUtil
{
	/**
	 * Returns true if the specified Dynamic object is in fact a struct (anonymous type).
	 * @param	obj - a Dynamic object
	 * @return Bool
	 */
	public static function updateConfig(config:WorkspaceConfiguration, strSection:String, strKey:String, value:Dynamic) : js.Promise.Thenable<Void>
	{
		var curr:DynamicObject<Dynamic> = config.get(strSection, null);
		if(curr == null)
		{
			curr = {};
		}
		curr.set(strKey, value);

		return config.update(strSection, curr, true);
	}
	

} // end of ConfigUtil class 

/**
 *  Wrapper for anonymous structures.
 *  Taken from  http://nadako.github.io/rants/posts/2014-05-21_haxe-dynamicobject.html
 *  Thanks, Dan.
 */
abstract DynamicObject<T>(Dynamic<T>) from Dynamic<T> {

    public inline function new(?obj:Dynamic<T>) {
		this = (obj == null) ? {} : obj;
    }

    @:arrayAccess
    public inline function set(key:String, value:T):Void {
        Reflect.setField(this, key, value);
    }

    @:arrayAccess
    public inline function get(key:String):Null<T> {
        #if js
        return untyped this[key];
        #else
        return Reflect.field(this, key);
        #end
    }

    public inline function exists(key:String):Bool {
        return Reflect.hasField(this, key);
    }

    public inline function remove(key:String):Bool {
        return Reflect.deleteField(this, key);
    }

    public inline function keys():Array<String> {
        return Reflect.fields(this);
    }
}