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
package wiggin.codedox;

import vscode.WorkspaceConfiguration;
import vscode.TextEditor;
import vscode.TextEditorEdit;
import vscode.Position;
import vscode.TextLine;
import vscode.Range;
import vscode.MessageItem;
import wiggin.codedox.License;
import wiggin.util.JsonUtil;
import wiggin.util.RegExUtil;
import wiggin.util.ConfigUtil;
import wiggin.util.StructUtil;

/**
 *  Implements command for inserting file header at top of files.
 */
class FileHeader
{
	/** Templates key */
	public static inline var TEMPLATES = CodeDox.FEATURE_FILEHEADER + ".templates";

	/** Params key */
	public static inline var PARAMS = CodeDox.FEATURE_FILEHEADER + ".params";

	/**
	 *  Constructor
	 */
	public function new()
	{
	}

	/**
	 *  Implementation of the `codedox.insertFileHeader` command.
	 *  @param line - optional `TextLine` to replace  
	 *  @param editor - the `TextEditor`
	 *  @param edit - the `TextEditorEdit`
	 */
	public function insertFileHeader(line:TextLine, editor:TextEditor, edit:TextEditorEdit) : Void
	{
		var str = getFileHeader(editor.document.languageId);

		// If the file already begins with this file header don't insert it again.
		var doc = editor.document;
		var range = new Range(doc.positionAt(0), doc.positionAt(str.length));
		var strDoc = doc.getText(range);
		if(str.length == 0 || strDoc != str)
		{
			if(line != null)
			{
				edit.replace(line.rangeIncludingLineBreak, str);
			}
			else
			{
				edit.insert(new Position(0, 0), str);
			}
		}
	}

	/**
	 *  Generates a file header string based on config.
	 *  @param strLang - the language id for the current editor document. e.g. "haxe"
	 */
	private function getFileHeader(strLang:String) : String
	{
		var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration();

		var strTemplate = getTemplate(config, strLang);
		strTemplate = populateTemplate(config, strTemplate, strLang);
		return strTemplate + "\n";
	}

	/**
	 *  Fetches the template associated with the language id or the default.
	 *
	 *  @param config - the `WorkspaceConfiguration` containing settings
	 *  @param strLang - the language id for the current editor document. e.g. "haxe"
	 *  @return String - the formatted template ready to be inserted into document 
	 */
	private function getTemplate(config:WorkspaceConfiguration, strLang:String) : String
	{
		var template:Array<String> = config.get(TEMPLATES + "." + strLang, null);
		if(template == null)
		{
			template = config.get(TEMPLATES + ".*", null);
		}

		if(template == null || template.length == 0)
		{
			if(config.get(CodeDox.EXTENSION_NAME + ".neverAskTemplate", false))
			{
				throw "";  // Abort the insert, but don't display an error.
			}
		
			var msg = CodeDox.EXTENSION_NAME + ": No file header template defined for " + strLang + ". Would you like to configure this feature?";
			var item1:MessageItem = {title:"Yes"};
			var item2:MessageItem = {title:"No", isCloseAffordance:true};
			var item3:MessageItem = {title:"Never"};
			Vscode.window.showErrorMessage(msg, item1, item2, item3).then(function(item:MessageItem){
				if(item.title == item1.title)
				{
					Vscode.commands.executeCommand(CodeDox.CMD_SETUP).then(onSetupComplete);
				}
				else if(item.title == item3.title)
				{
					setNeverAsk(config);	
				}
			});
			template = [""]; // This will erase what the user typed.
		}
		return template.join("\n");
	}

	/**
	 *  Called after the Setup wizard was triggered during file header insertion.
	 *  @param bResult - true if the wizard completed successfully
	 */
	private function onSetupComplete(bResult:Bool) : Void
	{
		if(bResult)
		{
			// Now that the setup wizard has created a minimal config, re-run the insert header command.
			js.Node.setTimeout(function(){Vscode.commands.executeCommand(CodeDox.CMD_INSERT_FILE_HEADER);}, 1000);
		}
	}

	/**
	 *  Populates `strTemplate` by substituting `${...}` patterns with parameters 
	 *  from the config.
	 *
	 *  @param config - the `WorkspaceConfiguration` containing settings
	 *  @param strTemplate - the template to populate
	 *  @param strLang - the language id for the current editor document. e.g. "haxe"
	 *  @return String - the populated  template 
	 */
	private function populateTemplate(config:WorkspaceConfiguration, strTemplate:String, strLang:String) : String
	{
		var paramsStar:Dynamic = config.get(PARAMS + ".*", null);
		var paramsLang:Dynamic = config.get(PARAMS + "." + strLang, null);
		var params:Dynamic = StructUtil.mergeStruct(paramsStar, paramsLang);

		var mapParams:Map<String,Dynamic> = JsonUtil.isStruct(params) ? JsonUtil.structToMap(params) : new Map();

		addDefaultParams(mapParams, config);
		var mapParamsNorm:Map<String,String> = normalizeParams(mapParams);

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
	 *  Adds the default parameters to `map`. Default params are things like
	 *  current year, date, time, etc. 
	 *
	 *  @param map - the map to populate.
	 *  @param config - the `WorkspaceConfiguration` containing settings
	 */
	private static function addDefaultParams(map:Map<String,Dynamic>, config:WorkspaceConfiguration) : Void
	{
		var date = Date.now();

		setIfAbsent(map, "year", Std.string(date.getFullYear()));
		setIfAbsent(map, "month", Std.string(date.getMonth() + 1));
		setIfAbsent(map, "day", Std.string(date.getDate()));

		setIfAbsent(map, "timestamp", date.toString());
		setIfAbsent(map, "time24h", DateTools.format(date, "%T"));

		setIfAbsent(map, "date", DateTools.format(date, "%F"));
		setIfAbsent(map, "time", DateTools.format(date, "%l:%M:%S %p"));

		var settings = CodeDox.getSettings();

		setIfAbsent(map, "commentbegin", settings.strCommentBegin);
		setIfAbsent(map, "commentprefix", settings.strCommentPrefix);
		setIfAbsent(map, "commentend", settings.strCommentEnd);
		setIfAbsent(map, "headerbegin", settings.strHeaderBegin);
		setIfAbsent(map, "headerprefix", settings.strHeaderPrefix);
		setIfAbsent(map, "headerend", settings.strHeaderEnd);

		addDefaultLicenses(map);
	}

	/**
	 *  Adds the default parameters to `map`. Default params are things like
	 *  current year, date, time, etc. 
	 *
	 *  @param map - the map to populate.
	 *  @param config - the `WorkspaceConfiguration` containing settings
	 */
	private static function addDefaultLicenses(map:Map<String,Dynamic>) : Void
	{
		var arr:Array<License> = wiggin.codedox.Setup.getDefaultLicenses();
		for(license in arr)
		{
			setIfAbsent(map, license.name, license.text.join("\n"));
		}
	}

	/**
	 *  Utility method to set map entries only if no mapping exists.
	 *
	 *  @param map - the map to populate
	 *  @param strKey - the key to check
	 *  @param strValue - the value to set
	 */
	private static inline function setIfAbsent(map:Map<String,Dynamic>, strKey:String, strValue:String) : Void
	{
		if(!map.exists(strKey))
		{
			map.set(strKey, strValue);
		}
	}

	/**
	 *  Takes a `Map` of dynamic values and converts to a map of strings.
	 *  Also converts the keys to "${...}" fields, properly escaped for regex.
	 *
	 *  @param map - the map to convert
	 *  @return converted map
	 */
	private function normalizeParams(params:Map<String,Dynamic>) : Map<String,String>
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
	 *  Updates the user's config so that it will never offer to choose a default template.
	 *  @param config - the `WorkspaceConfiguration` to write to
	 */
	private static function setNeverAsk(config:WorkspaceConfiguration) : Void
	{
		var update = {neverAskTemplate:true};
		ConfigUtil.update(config, CodeDox.EXTENSION_NAME, update).then(
			function(Void)
			{
				#if debug
				trace(CodeDox.EXTENSION_NAME + ".neverAskTemplate set to true successfully.");
				#end
			}, 
			function(result)
			{
				#if debug
				trace("Failed to set " + CodeDox.EXTENSION_NAME + ".neverAskTemplate");
				trace(result);
				#end
			}
		);
	}

} // end of FileHeader class