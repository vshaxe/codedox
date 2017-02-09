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

/**
 *  Methods useful when manipulating strings. All members are static.
 */
class StringUtil
{
	/**
	* Returns true if the specified string is non-null and is not empty.
	*
	* @param str - the string to check for characters
	* @return Bool
	*/
	public inline static function hasChars(str:String) : Bool
	{
		return (str != null && str.length > 0);
	}
	
	/**
	* Removes all whitespace from a string. Any spaces, tabs, newlines will be
	* removed.
	*
	* @param str - the string to remove whitespace from
	* @return String
	*/
	public static function removeWhitespace(str:String) : String
	{
		if (!hasChars(str)) { return str; }

		var r = ~/\s/g;
		var strOut = r.replace(str, "");
		return strOut;
	}

	/**
	 * Removes whitespace from beginning and end of the specified string.
	 * @param  str - source string
	 * @return String
	 */
	public static inline function trim(str:String) : String
	{
		return (str != null && str.length > 0) ? StringTools.trim(str) : str;
	}

	/**
	 * Replace all occurences of <code>strSub</code> in <code>str</code> with <code>strRepl</code>.
	 * @param  str     - source string
	 * @param  strSub  - string to search for
	 * @param  strRepl -  string to reaplace with
	 * @return String
	 */
	public static inline function replaceAll(str:String, strSub:String, strRepl:String) : String
	{
		return StringTools.replace(str, strSub, strRepl);
	}

	/**
	* Pads the end of a string with `charPad` characters, until the string is at least 
	* `iMinSize` in length.  If the string is already `iMinSize` then the original string 
	* is returned.
	*
	* @param str - source string to pad
	* @param iMinSize - minimum string length required.
	* @param charPad - character used if padding is needed.
	* @return String - which is at least `iMinSize` in length
	*/
	public static function padTail(str:String, iMinSize:Int, charPad:String) : String
	{
		str = (str == null) ? "" : str;
		iMinSize = (iMinSize < 0) ? 0 : iMinSize;

		if(str.length >= iMinSize || !StringUtil.hasChars(charPad))
		{
			return str;
		}
		else
		{
			return StringTools.rpad(str, charPad, iMinSize);
		}
	}

	/**
	* Ensures a string reference is never null, by returning an empty string if needed. 
	*
	* @param str - the string to check 
	* @return String - original string or empty string if null
	*/
	public static inline function toEmptyIfNull(str:String) : String
	{
		return (str == null) ? "" : str;
	}

	/**
	* Escapes whitespace from string, typically for logging and debugging.
	* Replaces with:
	*   \s = space
	*   \t = tab
	*	\n = newline
	*	\r = carriage return
	*
	* @param str - the string to escape 
	* @return String - escaped string
	*/
	public static function escapeWhitespace(str:String) : String
	{
		if(!hasChars(str)) { return str; }
		str = replaceAll(str, "\t", "\\t");
		str = replaceAll(str, "\n", "\\n");
		str = replaceAll(str, "\r", "\\r");
		str = replaceAll(str, " ", "\\s");
		return str;
	}

    /**
     * Returns an iterator for the specified string.
     * @return a StringIterator instance
     */
	public static inline function iterator(str:String) : StringIterator
	{
		return new StringIterator(str);
	}

	/**
	* Returns the specified rightmost characters in the string. If the string is
	* shorter than the requested number of characters then the source string is
	* returned. If a null string is passed, then null is returned.
	*
	* @param str - source string
	* @param iCount - maximum number of characters to return
	* @return String - the rightmost <code>iCount</code> characters of the source or null.
	*/
	public static function right(str:String, iCount:Int) : String
	{
		var strRight:String = null;
		if (str != null)
		{
			var iSrcLen:Int = str.length;

			if (iCount == 0)
			{
				strRight = "";
			}
			else if (iCount >= iSrcLen)
			{
				strRight = str;
			}
			else
			{
				strRight = str.substring(iSrcLen - iCount, iSrcLen);
			}
		}
		return strRight;
	}

	/**
	* Returns the specified leftmost characters in the string. If the string is
	* shorter than the requested number of characters then the source string is
	* returned. If a null string is passed, then null is returned.
	*
	* @param str - source string
	* @param iCount - maximum number of characters to return
	* @return String - the leftmost <code>iCount</code> characters of the source or null.
	*/
	public static function left(str:String, iCount:Int) : String
	{
		var strLeft:String = null;
		if (str != null)
		{
			var iSrcLen:Int = str.length;

			if (iCount == 0)
			{
				strLeft = "";
			}
			else if (iCount >= iSrcLen)
			{
				strLeft = str;
			}
			else
			{
				strLeft = str.substring(0, iCount);
			}
		}
		return strLeft;
	}

	/**
	 *  Reverses the input string and returns the result.
	 *  @param str - the input string
	 *  @return reversed string, or null if null input
	 */
	public static function reverse(str:String) : String
	{
		if(str == null || str == "")
		{
			return str;
		}

		var sb = new StringBuf();
		for(i in -str.length+1...1)
		{
			sb.addChar(StringTools.fastCodeAt(str, -i));
		}
		return sb.toString();
	}

	/**
	 *  Returns true if any `arrStrSub` strings are found within `str`.
	 *  @param str - the string to search
	 *  @param arrStrSub - array of strings to search for
	 *  @return Bool - false if none of the sub strings are found in `str`
	 */
	public static function contains(str:String, arrStrSub:Array<String>) : Bool
	{
		for(strSub in arrStrSub)
		{
			if(str.indexOf(strSub) != -1)
			{
				return true;
			}
		}
		return false;
	}

	/**
	 *  Returns true if the string `str` starts with `strStart`. If either param
	 *  is null then false is returned.
	 *  @param str - the string to search 
	 *  @param strStart - the substring to search for
	 *  @return Bool - true if `str` starts with `strStart` and both are not null
	 */
	public static inline function startsWith(str:String, strStart:String) : Bool
	{
		return (str != null && strStart != null) ? StringTools.startsWith(str, strStart) : false;
	}

	/**
	 *  Returns true if the string `str` ends with `strEnd`. If either param
	 *  is null then false is returned.
	 *  @param str - the string to search 
	 *  @param strEnd - the substring to search for
	 *  @return Bool - true if `str` ends with `strEnd` and both are not null
	 */
	public static inline function endsWith(str:String, strEnd:String) : Bool
	{
		return (str != null && strEnd != null) ? StringTools.startsWith(str, strEnd) : false;
	}

} // end of StringUtil class

/**
 * Simple class providing an iterator for walking strings.
 */
class StringIterator 
{
    /** The string being iterated over */
    private var s:String;
    /** Tracks position in the iteration */
    private var i:Int;

    /**
     * Constructor
     * @param  s - the string to iterate over. Cannot be null.
     */
    public function new(s:String) 
    {
        this.s = (s == null) ? "" : s;
        i = 0;
    }

    /**
     * Returns true if more chars are left to iterate over.
     * @return Bool
     */
    public function hasNext() : Bool
    {
	    return i < s.length;
    }

    /**
     * Returns the next char in the iteration
     * @return String
     */
    public function next() : String
    {
    	return s.charAt(i++);
    }

} // End of StringIterator class
