package ;

class Test 
{
	private var m_strToken:String;  

	public static function main()
	{
		trace(getMessage("Hello", 2));
	}

	/**
	 * Formats a simple message.
	 * @param str the string to prefix
	 * @param num the number suffix
	 * @return formatted string
	 * @throws exp if str is null 
	 * @see some other stuff
	 */
	private static function getMessage(str:String, num:Int) : String
	{
		if (str == null) throw "str can't be null";
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

	public function makeCB(str:String, defCallback:String->Int->Bool, ?blap:Test) : String->Int->Bool
	{
		return null;		
	}

	public function paramInference(foo)
	{ 
	
	}

	private function noBraces(i:Int) return switch(i) {
		case 0: "0";
		case 1: "1";
		default: "?";
	}

}

