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

import vscode.TextDocument;
import vscode.TextLine;
import vscode.Position;
import vscode.TextEditor;
import vscode.TextEditorEdit;
import wiggin.util.StringUtil;

/**
 *  Enum determines which direction a search progresses.
 */
enum Direction { Forward; Backward; }

/**
 *  Result of a `ParseUtil.findText` call.
 */
typedef FoundText = {posStart:Position, posEnd:Position}

/**
 *  Methods useful when parsing strings. All members are static.
 */
class ParseUtil
{

	/**
	 * Split a string by commas, but only commas that are outside any
	 * quotes or brackets.
	 * For example:  
	 *		"arr:Map<String,Int>, msg:String='Hi, there!', color:Color=rgb(255,0,0)"
	 *	 becomes
	 *		["arr:Map<String,Int>", "msg:String='Hi, there!'","color:Color=rgb(255,0,0)"]
	 *
	 * Ported from: https://github.com/spadgos/sublime-jsdocs/blob/master/jsdocs.py 
	 *
	 * @param str - the string to parse
	 * @return Array<String> - or empty array if `str` is empty or null 
	 */
	public static function splitByCommas(str:String) : Array<String>
	{
		var arr:Array<String> = [];
		if(StringUtil.hasChars(str))
		{
			 var strToken = "";
			 var strOpenQuote = "\"'<({[";
			 var strCloseQuote = "\"'>)}]";
			 var strMatchingQuote = "";
			 var bInsideQuotes = false;
			 var bNextIsLiteral = false;

			 for(ch in StringUtil.iterator(str))
			 {
				 if(bNextIsLiteral) 
				 {
					 // Previous char was a '\'
					 strToken += ch;
					 bNextIsLiteral = false;
				 }
				 else if(bInsideQuotes)
				 {
					 if(ch == "\\")
					 {
						 bNextIsLiteral = true;
					 }
					 else
					 {
						 strToken += ch;
						 if(ch == strMatchingQuote) { bInsideQuotes = false; } 
					 }
				 }
				 else
				 {
					 if(ch == ",")
					 {
						 arr.push(StringTools.trim(strToken));
						 strToken = "";
					 }
					 else
					 {
						 strToken += ch;
						 var idx = strOpenQuote.indexOf(ch);
						 if(idx > -1)
						 {
							 strMatchingQuote = strCloseQuote.charAt(idx);
							 bInsideQuotes = true;
						 }
					 }
				 }
			 }
			 arr.push(StringTools.trim(strToken));
		}
		return arr;
	}

	/**
	 *  Finds a line within the `TextDocument` that matches `regex`. The search moves either 
	 *  `Direction.Forward` or `Direction.Backward` starting from `pos`.  If no match is
	 *  found before BOF or EOF then null is returned.
	 *
	 *  @param doc - the `TextDocument` to search
	 *  @param pos - starting position of search
	 *  @param dir - direction of search
	 *  @param regex - the `EReg` pattern to search for   
	 *  @return the first `TextLine` found matching `regex` or null 
	 */
	public static function findLine(doc:TextDocument, pos:Position, dir:Direction, regex:EReg) : Null<TextLine> 
	{
		pos = doc.validatePosition(pos);
		var iDir = (dir == Direction.Forward) ? 1 : -1;

		var lineFound:TextLine = null;

		var iMaxLine = doc.lineCount - 1;
		var iLine = pos.line;
		var line:TextLine;
		while(iLine >= 0 && iLine <= iMaxLine)
		{
			line = doc.lineAt(iLine);
			if(line != null && regex.match(line.text))
			{
				lineFound = line;
				break;
			}
			iLine += iDir;
		}
		return lineFound;
	}

	/**
	 *  Finds the first occurance of text within a `TextLine`. 
	 *
	 *  @param line - the `TextLine` to search
	 *  @param ?iStartChar - optional starting position of search within the `TextLine`. Defaults to first character
	 *  @param strText - the text to search for
	 *  @return a `FoundText` object containing start and end position of the found text, or null if not found
	 */
	public static function findTextInLine(line:TextLine, iStartChar:Int = 0, strText:String) : Null<FoundText>
	{
		var ft:FoundText = null;
		var strLine = line.text;
		if(StringUtil.hasChars(strLine) && iStartChar < strLine.length)
		{
			var i = strLine.indexOf(strText, iStartChar);
			if(i != -1)
			{
				ft = {posStart:new Position(line.lineNumber, i), 
				      posEnd:new Position(line.lineNumber, i + strText.length)};
			}
		}
		return ft; 
	}

	/**
	 *  Finds the first occurance of text within a `TextDocument`. 
	 *
	 *  @param doc - the `TextDocument` to search
	 *  @param ?posStart - optional starting position of search within the `TextDocument`. Defaults to top of document
	 *  @param strText - the text to search for
	 *  @return a `FoundText` object containing start and end position of the found text, or null if not found
	 */
	public static function findText(doc:TextDocument, ?posStart:Position, strText:String) : Null<FoundText>
	{
		posStart = (posStart == null) ? new Position(0,0) : doc.validatePosition(posStart);
		var ft:FoundText = null;

		var iMaxLine = doc.lineCount - 1;
		var iLine = posStart.line;
		var iStartIndex = posStart.character;
		var line:TextLine;
		while(iLine >= 0 && iLine <= iMaxLine)
		{
			line = doc.lineAt(iLine);
			if(line != null)
			{
				ft = findTextInLine(line, iStartIndex, strText);
				if(ft != null)
				{
					break;
				}
				iStartIndex = 0;
			}
			iLine++;
		}
		return ft; 
	}

	/**
	 *  Walks backward in the document looking for a whitespace-only line, stopping
	 *  at the found blank line or end of the previous expression. If a blank line
	 *  was not found one is inserted. If `pos` is already on a blank line then the 
	 *  original `Position` is returned unchanged.
	 *
	 *  @param editor - `TextEditor` to parse
	 *  @param pos - starting position
	 *  @return `Position` of blank line 
	 */
	public static function findPrevBlankLine(editor:TextEditor, pos:Position) : Position
	{
		var doc = editor.document;
		var posBack = pos.with({character:0});
		while(posBack.line > 0)
		{
			var line = doc.lineAt(posBack);
			if(line.isEmptyOrWhitespace)
			{
				break;
			}

			var strLine = line.text;
			if(strLine.indexOf("}") != -1 || strLine.indexOf(";") != -1)
			{
				// No blank line found - insert one.
				posBack = posBack.with({line:posBack.line + 1});
				editor.edit(function(tee:TextEditorEdit) {tee.insert(posBack,"\n");});
				posBack = posBack.with({line:posBack.line + 1});
				break;
			}
			posBack = posBack.with({line:posBack.line - 1});
		}
		return posBack;
	}

	/**
	 *  Returns a string containing the right amount of tabs and/or spaces based 
	 *  on the config settings.  Indent is calculated by counting the whitespace 
	 *  at the beginning of the previous non-whitespace line relative to
	 *  `pos`.
	 *
	 *  @param line - the `TextLine` containing the `function` keyword
	 *  @return String - tabs and/or spaces enough to fill the calculated indent 
	 */


	/**
	 *  Returns a string containing the right amount of tabs and/or spaces based 
	 *  on the config settings.  Indent is calculated by counting the whitespace 
	 *  at the beginning of the previous non-whitespace line relative to
	 *  `pos`.
	 *  @param doc - the `TextDocument` to search
	 *  @param pos - the `Position` in the document to search from
	 *  @return String - containing only whitespace
	 */
	public static function getIndent(doc:TextDocument, pos:Position) : String
	{
		var workspace = Vscode.workspace;
		var settings:vscode.WorkspaceConfiguration = workspace.getConfiguration();

		var iTabSize = settings.get("editor.tabSize", 1);
		var bInsertSpaces = settings.get("editor.insertSpaces", true);

		// Find the closest non-whitespace line. 
		var strIndent:String;
		var line = ParseUtil.findLine(doc, pos, Direction.Backward, ~/[^\s]/);
		if(line != null && StringTools.startsWith(line.text, "{"))
		{
			// Opening bracket on first character means we're at the beginning of a type so 
			// just indent one tab stop.
			strIndent = makeIndent(iTabSize, bInsertSpaces, iTabSize);
		}
		else if(line != null)
		{
			// Use the indent of this found line.
			strIndent = line.text.substring(0, line.firstNonWhitespaceCharacterIndex);
		}
		else
		{
			// Could not determine indent.
			strIndent = "";
		}
		return strIndent;
	}

	/**
	 *  Generates a string with `iIndent` characters of whitespace, using either all spaces
	 *  or the optimal combination of tabs and spaces.
	 *  @param iIndent - the amount of whitespace needed
	 *  @param bInsertSpaces - if true then only use spaces, otherwise tabs and spaces
	 *  @param iTabSize - tab width in characters
	 *  @return String - a string containing only whitespace
	 */
	public static function makeIndent(iIndent:Int, bInsertSpaces:Bool, iTabSize:Int) : String
	{
		var strIndent:String;
		if(bInsertSpaces)
		{
			strIndent = StringUtil.padTail("", iIndent, " ");
		}
		else
		{
			var iTabs = Math.floor(iIndent / iTabSize);
			strIndent = StringUtil.padTail("", iTabs, "\t");
			strIndent += StringUtil.padTail("", iIndent - (iTabs * iTabSize), " "); 
		}
		return strIndent;
	}

} // End of ParseUtil class