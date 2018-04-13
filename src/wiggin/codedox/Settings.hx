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
package wiggin.codedox;

import vscode.WorkspaceConfiguration;
import wiggin.util.StringUtil;
import wiggin.util.DynamicObject;
import wiggin.codedox.Resource;

private typedef Context = {strLanguage:String, config:WorkspaceConfiguration}

/** 
 *  Provides per language configuration settings.
 */
class Settings
{
	/** The properties  */	
	public var autoPrefixOnEnter(default,null) : Bool;
	public var autoInsert(default,null) : Bool;
	public var autoInsertHeader(default,null) : Bool;
	public var strParamFormat(default,null) : String;
	public var strReturnFormat(default,null) : String;
	public var strCommentBegin(default,null) : String;
	public var strCommentEnd(default,null) : String;
	public var strCommentPrefix(default,null) : String;
	public var strCommentDescription(default,null) : String;
	public var strCommentToken(default,null) : String;
	public var strCommentTrigger(default,null) : String;
	public var alwaysMultiline(default,null) : Bool;
	public var strAutoClosingClose(default,null) : String;
	public var strAutoClosingCloseAlt(default,null) : String;
	public var strHeaderBegin(default,null) : String;
	public var strHeaderEnd(default,null) : String;
	public var strHeaderPrefix(default,null) : String;
	public var strHeaderTrigger(default,null) : String;
	public var allowOptionalArgs(default,null) : Bool;

	/** The resource uri for which these settings were loaded. */
	public var resourceUri(default,null) : vscode.Uri;

	/** The language id for which these settings were loaded. */
	public var strLanguage(default,null) : String;
	
	/** Caches */
	private static var  s_mapCache:Map<String,Settings> = new Map();

	/** Key for language specific properties */
	public static var LANGUAGES = CodeDox.EXTENSION_NAME + ".languages";

	/**
	 *  Fetches a `Settings` object based on the specified resource uri and language.
	 *  @param resource - the `Resource` for which setting will be fetched.
	 *  @return a new or previously cached `Settings` object
	 */
	public static function fetch(resource:Resource) : Settings
	{
		var strKey = resource.toString();

		var settings:Settings = s_mapCache.get(strKey);
		if(settings == null)
		{
			settings = new Settings(resource);
			s_mapCache.set(strKey, settings);
		}
		return settings;
	}

	/**
	 *  Clears the settings cache.
	 */
	public static function clearCache() : Void
	{
		s_mapCache = new Map();
	}

	/**
	 *  Constructor
	 *  @param resource - the `Resource` to fetch settings for.
	 */
	private function new(resource:Resource)
	{
		var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration(null, resource.uri);
		var ctx:Context = {strLanguage:strLanguage, config:config};

		var strCommentBegin = getProp("commentbegin", "/**", ctx);
		var strHeaderBegin = getProp("headerbegin", "/*", ctx);
		var strAutoClose = getAutoClosingClose(strCommentBegin, false);
		var strAutoCloseAlt = getAutoClosingClose(strCommentBegin, true);

		this.resourceUri = resource.uri;
		this.strLanguage = resource.languageId;
		this.autoPrefixOnEnter = getProp("autoPrefixOnEnter", true, ctx);
		this.autoInsert = getProp("autoInsert", true, ctx);
		this.autoInsertHeader = getProp("autoInsertHeader", true, ctx);
		this.strParamFormat = getProp("paramFormat", "@param ${name} - ", ctx);
		this.strReturnFormat = getProp("returnFormat", "@return ${type}", ctx);
		this.strCommentBegin = strCommentBegin;
		this.strCommentEnd = getProp("commentend", " */", ctx);
		this.strCommentPrefix = getProp("commentprefix", " *  ", ctx);
		this.strCommentDescription = getProp("commentdescription", "[Description]", ctx);
		this.strCommentToken = "[]";
		this.strCommentTrigger = StringUtil.right(strCommentBegin, 1);
		this.alwaysMultiline = getProp("alwaysMultiline", true, ctx);
		this.strAutoClosingClose = (strAutoClose != null) ? strAutoClose : "";
		this.strAutoClosingCloseAlt = (strAutoCloseAlt != null) ? strAutoCloseAlt : "";
		this.strHeaderBegin = getProp("headerbegin", "/*", ctx);
		this.strHeaderEnd = getProp("headerend", "*/", ctx);
		this.strHeaderPrefix = getProp("headerprefix", " *", ctx);
		this.strHeaderTrigger = StringUtil.right(strHeaderBegin, 1);
		this.allowOptionalArgs = getProp("allowOptionalArgs", false, ctx);
	}

	/**
	 *  Fetches a property based on language id. If a language specific value is not found then a global
	 *  value is fetched. If no global value is found then the specfied default is returned.
	 *  @param strKey - the property key to fetch
	 *  @param def - the default value
	 *  @param ctx - a `Context` containing language id and `WorkspaceConfiguration`
	 *  @return T
	 */
	private function getProp<T>(strKey:String, def:T, ctx:Context) : T
	{
		// First try to find the key in languages.
		var val:Null<T> = null;
		var strSubKey = LANGUAGES + "." + ctx.strLanguage; 
		
		if(ctx.config.has(strSubKey))
		{
			val = ctx.config.get(strSubKey + "." + strKey);
		}
		
		if(val == null)
		{
			// Global.
			val = ctx.config.get(CodeDox.EXTENSION_NAME + "." + strKey);
			if(val == null)
			{
				val = def;
			}
		}
		return val;
	}

	/**
	 *  Returns an array of language ids supported by codedox.  The language ids are listed
	 *  in the "codedox.languages" property of the config. 
	 *  
	 *  "haxe" is always supported regardless of whether it is listed or not.
	 *  
	 *  @return Array<String>
	 */
	public static function getSupportedLanguages() : Array<String>
	{
		var arr = ["haxe"];
		var config = Vscode.workspace.getConfiguration();
		var langs:DynamicObject<String> = config.get(LANGUAGES);
		if(langs != null)
		{
			for(key in langs.keys())
			{
				if(key != "haxe")
				{
					arr.push(key);
				}
			}
		}
		return arr;
	}

	/**
	 *  Returns the autoclosing close string for the specified opening string.
	 *  e.g. "\**" is usually closed with "*\".
	 *  
	 *  @param strAutoClosingOpen - the opening string of an autoclosing pair
	 *  @param bAlt - true if the alternative close pair is to be returned
	 *  @return String or null
	 */
	private static function getAutoClosingClose(strAutoClosingOpen:String, ?bAlt = false) : Null<String>
	{
		// Dammit. Vscode won't let me lookup the LanguageConfiguration settings.
		// Maybe this will be added in the future: https://github.com/Microsoft/vscode/issues/2871

		// We'll have to hack something for now...
		return switch(strAutoClosingOpen)
		{
			// Haxe extension configures vscode to autoclose with double asterisk.
			case "/**": (bAlt) ? "*/" : "**/";  

			// Just reverse the open until we can read the real value??
			default: StringUtil.reverse(strAutoClosingOpen);  
		}
	}

} // end of Settings class