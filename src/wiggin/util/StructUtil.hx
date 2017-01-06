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

import wiggin.util.DynamicObject;

/**
 *  Static methods useful for working with anonymous structures.
 */
class StructUtil
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
	 *  Merges two anonymous structures. This is a deep merge. 
	 *  If one of the inputs is null then the non-null struct is returned. 
	 *  If both are null then the result is null. 
	 *  
	 *  In the case of key collisions, `struct2` overwrites `struct1`.  
	 *  Neither input is modified during the merge.
	 *  
	 *  Test:  http://try.haxe.org/#A6474
	 *  
	 *  @param	struct1 - an anonymous structure to merge
	 *  @param  struct2 - an anonymous structure to merge
	 *  @return Dynamic - a new, merged anonymous structure
	 */
	public static function mergeStruct(struct1:Dynamic, struct2:Dynamic) : Dynamic
	{
		if(struct1 == null) return struct2;
		if(struct2 == null) return struct1;
		if(struct1 == null && struct2 == null) return null;

		var merged:DynamicObject<Dynamic> = deepClone(struct1);
		var source:DynamicObject<Dynamic> = struct2;
		
		for(key in source.keys())
		{
			var valMerged = merged.get(key);
			var valSource = source.get(key);
			if(isStruct(valSource) && isStruct(valMerged))
			{
				merged.set(key, mergeStruct(valMerged, valSource));
			}
			else
			{
				merged.set(key, valSource);
			}
		}
		return merged;
	}

	/**
	 *  Performs a deep copy of the source structure and returns the 
	 *  result.
	 *  
	 *  Test: http://try.haxe.org/#A741B
	 *  
	 *  @param struct - the source.
	 *  @return Dynamic - an exact copy of the source
	 */
	public static function deepClone(struct:Dynamic) : Dynamic
	{
		if(struct == null) return null;

		var input:DynamicObject<Dynamic> = struct;
		var copy:DynamicObject<Dynamic> = {};

		for(key in input.keys())
		{
			var val = input.get(key);
			if(isStruct(val))
			{
				copy.set(key, deepClone(val));
			}
			else
			{
				copy.set(key, val);
			}
		}
		return copy;
	}

} // end of ConfigUtil class 

