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

import vscode.TextEditorEdit;
import vscode.TextEditor;
import vscode.TextLine;
import vscode.Position;
import wiggin.util.StringUtil;
import wiggin.util.MathUtil;
import wiggin.util.ParseUtil;
import wiggin.util.ParseUtil.Direction;
import wiggin.util.ParamUtil;

typedef Param = {name:String, type:String}
typedef FunctionInfo = {params:Array<Param>, retType:String, strIndent:String}

/**
 *  Implements command for inserting a code comment at cursor location.
 */
class Commenter
{
	/** Flag set when a functon comment insert has been made. */
	public var isInsertPending(default,default):Bool;

	/**
	 *  Constructor
	 */
	public function new()
	{
		isInsertPending = false;
	}

	/**
	 *  Implementation of the `codedox.comment.insert` command.
	 *  @param line - the `TextLine` to replace
	 *  @param editor - the `TextEditor`
	 *  @param edit - the `TextEditorEdit` used to perform edit(s)
	 */
	public function insertComment(line:TextLine, editor:TextEditor, edit:TextEditorEdit) : Void
	{
		var strComment = getComment(line, editor); 

		if(strComment != null)
		{
			edit.replace(line.rangeIncludingLineBreak, strComment);
			this.isInsertPending = true;
		}
		else
		{
			CodeDox.log("insertComment aborted: no function to parse");
		}
	}

	/**
	 *  Generate the comment block string by parsing a function signature directly after the specified `TextLine`.
	 *  @param line - the `TextLine` to parse from
	 *  @param editor - the `TextEditor` used to extract text
	 *  @return String 
	 */
	private function getComment(line:TextLine, editor:TextEditor) : String
	{
		var strComment = null;
		var doc = editor.document;
		var posStart = line.range.end;

		// Grab the next 1KB of text.  That should be more than enough
		// to capture the next method declaration.
		var iOffset = doc.offsetAt(posStart);
		var posEnd = doc.positionAt(iOffset + 1024);
		var range = new vscode.Range(posStart, posEnd);
		range = doc.validateRange(range);
		var strText = doc.getText(range);

		// Match the first method declaration. Group 1 will contain the
		// parameters, group 2 will contain the return type.
		var r = getFunctionRegex(doc.languageId);
		if(r.match(strText))
		{
			var iPosMatch = r.matchedPos().pos;
			var strParams = StringUtil.trim(r.matched(1));
			var strReturnType = StringUtil.trim(r.matched(2));

			// Make sure this really is the start of a method (as best we can without
			// access to document structure).
			var settings = CodeDox.getSettings();
			var strPreamble = strText.substr(0, iPosMatch + 1);
			if(!StringUtil.contains(strPreamble, [settings.strCommentBegin, settings.strCommentEnd, "{", "}", ";"]))
			{
				// Figure out the indentation used by counting whitespace at the
				// beginning of the line that contains the keyword "function".
				var posMatch = doc.positionAt(iOffset + iPosMatch);
				var strIndent = ParseUtil.getIndent(doc, posMatch);
				
				// Parse the method parameters.
				var arrParams = parseParams(strParams, doc.languageId);

				#if debug
				var sb = new StringBuf();
				sb.add("*****\n");
				sb.add('Indent Len=');
				sb.add(strIndent.length);
				sb.add("\n");
				sb.add('Indent=');
				sb.add(StringUtil.escapeWhitespace(strIndent));
				sb.add("\n");
				sb.add('params=');
				sb.add(arrParams);
				sb.add("\n");
				sb.add('return=');
				sb.add(strReturnType);
				sb.add("\n");
				sb.add("*****\n");
				CodeDox.log(sb.toString());
				#end

				strComment = composeComment(strIndent, arrParams, strReturnType);
			}
			else
			{
				// Figure out the indentation used by counting whitespace at the
				// beginning of the next non-blank line.
				var lineCheck:TextLine = ParseUtil.findLine(doc, new Position(posStart.line + 1, 0), Direction.Forward, ~/[^\s]+/);
				var strIndent = (lineCheck != null) ? ParseUtil.getIndent(doc, lineCheck.range.start) : "";
				strComment = strIndent + settings.strCommentBegin + "  " + settings.strCommentEnd + "\n";
			}
		}
		return strComment;
	}

	/**
	 *  Returns the `EReg` needed to parse a function for the current language. 
	 *
	 *  @param strLangaugeId - the langauge id of the current document
	 *  @return an `EReg` 
	 */
	private static function getFunctionRegex(strLangaugeId:String) : EReg
	{
		var haxe_regex:EReg;
		var js_regex:EReg;

		haxe_regex = ~/(?:function\s+\w+\s*)(?:<[\s\S]+>\s*)*\(([^)]*)\)(?:(?:(?:\s*:\s*)*(\w*[^{;]*)))/;
		js_regex = ~/(?:function\s*\w*\s*)(?:<[\s\S]+>\s*)*\(([^)]*)\)(?:(?:(?:\s*:\s*)*(\w*[^{;]*)))/;

		switch(strLangaugeId)
		{
			case "haxe":
				return haxe_regex;
			case "javascript":
				return js_regex;
			case "html":
				return js_regex;
			// TODO: other languages here.
			default:
				return haxe_regex;
		}	
	}

	/**
	 *  Composes a comment block based on the specified indent and method parameters. 
	 *
	 *  @param strIndent - string used to indent each comment line
	 *  @param arrParams - array of `Param` structs
	 *  @param strReturnType - the return type 
	 *  @return String - the new comment block 
	 */
	private static function composeComment(strIndent:String, ?arrParams:Array<Param>, ?strReturnType:String) : String
	{
		var settings = CodeDox.getSettings();

		var sb = new StringBuf();
		sb.add(strIndent);
		sb.add(settings.strCommentBegin);
		sb.add("\n");
		
		sb.add(strIndent);
		sb.add(settings.strCommentPrefix);
		sb.add(settings.strCommentDescription);
		sb.add("\n");

		if(arrParams != null && StringUtil.hasChars(settings.strParamFormat))
		{		
			for(item in arrParams)
			{
				sb.add(strIndent);
				sb.add(settings.strCommentPrefix);

				var mapP = ["name" => item.name, "type" => item.type];
				ParamUtil.addDefaultParams(mapP);
				var strP = ParamUtil.applyParams(settings.strParamFormat, mapP);
				sb.add(strP);
				
				sb.add("\n");
			}
		}

		if(StringUtil.hasChars(strReturnType) && strReturnType != "Void" && StringUtil.hasChars(settings.strReturnFormat))
		{
			sb.add(strIndent);
			sb.add(settings.strCommentPrefix);

			var mapR = ["type" => strReturnType];
			ParamUtil.addDefaultParams(mapR);
			var strR = ParamUtil.applyParams(settings.strReturnFormat, mapR);
			sb.add(strR);
						
			sb.add("\n");
		}
		sb.add(strIndent);
		sb.add(settings.strCommentEnd);
		sb.add("\n");
		return sb.toString();
	} 

	/**
	 *  Parses the method parameters and returns an array of `Param` objects.
	 *
	 *  @param strParams - string to parse
	 *  @param strLanguageId - the language id of the current document 
	 *  @return Array<Param> - an array of Params. Might be empty. 
	 */
	private static function parseParams(strParams:String, strLanguageId:String) : Array<Param>
	{
		var strParamSeparator:String;
		var idxName:Int;
		var idxType:Int;

		switch(strLanguageId)
		{
			case "haxe":
				strParamSeparator = ":";
				idxName = 0;
				idxType = 1;
			// TODO: additional language parsing here
			default:
				strParamSeparator = ":";
				idxName = 0;
				idxType = 1;
		}

		strParams = StringUtil.toEmptyIfNull(strParams);
		var arrParams:Array<Param> = [];
		var bAllowOptional = CodeDox.getSettings().allowOptionalArgs;

		var arr = ParseUtil.splitByCommas(strParams);
		for(item in arr)
		{
			item = StringTools.trim(item);
			if(StringUtil.hasChars(item))
			{	
				// Split name and type via the separator.
				var arrItem = item.split(strParamSeparator);
				var strType = (arrItem.length > 1) ? arrItem[idxType] : "";
				var strName = arrItem[MathUtil.min(arrItem.length - 1, idxName)];

				strType = StringTools.trim(strType);
				strName = StringTools.trim(strName);

				// Possibly remove "?" from optional params.
				if(!bAllowOptional && StringTools.startsWith(strName, "?"))
				{
					strName = strName.substr(1);
				}
				arrParams.push({name:strName, type:strType});
			}
		}
		return arrParams;
	} 

} // end of Commenter class