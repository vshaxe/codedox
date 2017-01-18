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
import wiggin.util.ParamUtil;
import wiggin.util.ConfigUtil;
import wiggin.util.StructUtil;

typedef SetupCompleteContext = {count:Int, strLang:String}

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
		var strTemplate = getTemplate(strLang);
		strTemplate = populateTemplate(strTemplate, strLang);
		return strTemplate + "\n";
	}

	/**
	 *  Fetches the template associated with the language id or the default.
	 *
	 *  @param strLang - the language id for the current editor document. e.g. "haxe"
	 *  @return String - the formatted template ready to be inserted into document 
	 */
	private function getTemplate(strLang:String) : String
	{
		var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration();
		var template:Array<String> = getTemplateConfig(strLang);
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
					var ctx:SetupCompleteContext = {count:0, strLang:strLang};
					Vscode.commands.executeCommand(CodeDox.CMD_SETUP).then(function(bResult){onSetupComplete(bResult,ctx);});
				}
				else if(item.title == item3.title)
				{
					setNeverAsk();	
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
	private function onSetupComplete(bResult:Bool, cxt:SetupCompleteContext) : Void
	{
		if(bResult)
		{
			// Work-around:  despite waiting for the Promise to resolve, sometimes the workspace config update
			//               is not available for reading right away. The latency seems to vary based on machine
			//               and load?  Here we'll try a few times then give up.
			var template = getTemplateConfig(cxt.strLang);
			if(template == null || template.length == 0)
			{
				if(cxt.count <= 10)
				{
					CodeDox.log("template still empty. Trying again, count=" + cxt.count);
					cxt.count++;
					js.Node.setTimeout(function(){onSetupComplete(bResult,cxt);}, 250);	
				}
			}
			else
			{
				// Now that the setup wizard has created a minimal config, re-run the insert header command.
				js.Node.setTimeout(function(){Vscode.commands.executeCommand(CodeDox.CMD_INSERT_FILE_HEADER);}, 10);
			}
		}
	}

	/**
	 *  Fetches the raw template data associated with the language id or the default.
	 *
	 *  @param strLang - the language id for the current editor document. e.g. "haxe"
	 *  @return Array<String> - the raw template data 
	 */
	private function getTemplateConfig(strLang:String) : Array<String>
	{
		var config = Vscode.workspace.getConfiguration();
		var template:Array<String> = config.get(TEMPLATES + "." + strLang, null);
		if(template == null)
		{
			template = config.get(TEMPLATES + ".*", null);
		}
		return template;
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
	private function populateTemplate(strTemplate:String, strLang:String) : String
	{
		var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration();
		var paramsStar:Dynamic = config.get(PARAMS + ".*", null);
		var paramsLang:Dynamic = config.get(PARAMS + "." + strLang, null);
		var params:Dynamic = StructUtil.mergeStruct(paramsStar, paramsLang);

		var mapParams:Map<String,Dynamic> = JsonUtil.isStruct(params) ? JsonUtil.structToMap(params) : new Map();
		addDefaultParams(mapParams);
		addDefaultLicenses(mapParams);
		var strRet = ParamUtil.applyParams(strTemplate, mapParams);
		return strRet;
	}

	/**
	 *  Adds the built-in parameters to `map`. Built-in params are things like
	 *  current year, date, time, etc. 
	 *
	 *  @param map - the map to populate.
	 */
	private static function addDefaultParams(map:Map<String,Dynamic>) : Void
	{
		// Add the built-in params like current year, date, time, etc.
		ParamUtil.addDefaultParams(map);
		
		var settings = CodeDox.getSettings();
		ParamUtil.setIfAbsent(map, "commentbegin", settings.strCommentBegin);
		ParamUtil.setIfAbsent(map, "commentprefix", settings.strCommentPrefix);
		ParamUtil.setIfAbsent(map, "commentend", settings.strCommentEnd);
		ParamUtil.setIfAbsent(map, "headerbegin", settings.strHeaderBegin);
		ParamUtil.setIfAbsent(map, "headerprefix", settings.strHeaderPrefix);
		ParamUtil.setIfAbsent(map, "headerend", settings.strHeaderEnd);
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
			ParamUtil.setIfAbsent(map, license.name, license.text.join("\n"));
		}
	}

	/**
	 *  Updates the user's config so that it will never offer to choose a default template.
	 */
	private static function setNeverAsk() : Void
	{
		var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration();
		var update = {neverAskTemplate:true};
		ConfigUtil.update(config, CodeDox.EXTENSION_NAME, update).then(
			function(Void)
			{
				CodeDox.log(CodeDox.EXTENSION_NAME + ".neverAskTemplate set to true successfully.");
			}, 
			function(result)
			{
				CodeDox.log("Failed to set " + CodeDox.EXTENSION_NAME + ".neverAskTemplate");
				CodeDox.log(result);
			}
		);
	}

} // end of FileHeader class