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

import vscode.OnEnterRule;
import wiggin.util.RegExUtil;
import wiggin.util.StringUtil;
import js.lib.RegExp;

/** 
 *  Provides `OnEnterRules` for language configurations.
 */
class EnterRules
{
	/**
	 *  Creates the `onEnterRules` to the language configuration specified in the `Settings`.
	 */
	public static function createRules(settings:Settings) : Array<OnEnterRule>
	{
		var strCommentBegin = StringUtil.trim(settings.strCommentBegin);
		var strCommentEnd = StringUtil.trim(settings.strCommentEnd);
		var strCommentPrefix = settings.strCommentPrefix;
		
		var esc = RegExUtil.escapeRegexChars;
		var cprefix = esc(StringUtil.trim(strCommentPrefix));
		var cbegin = esc(strCommentBegin);
		var cend = esc(strCommentEnd);

		var cend1 = esc(strCommentEnd.substr(0, 1));
		var cend2 = esc(strCommentEnd.substring(1));

		var onEnterRules:Array<OnEnterRule> = [
			{				
				// e.g. /** | */
				// beforeText: ^\s*\/\*\*(?!\/)([^\*]|\*(?!\/))*$
				//  afterText: ^\s*\*\/$
				beforeText: new RegExp("^\\s*" + cbegin + "(?!"+ cend + ")([^" + cend1 + "]|" + cend1 + "(?!" + cend2 + "))*$"),
				afterText: new RegExp("^\\s*" + cend + "$"),
				action: { indentAction: vscode.IndentAction.IndentOutdent, appendText: strCommentPrefix }
			},
			{
				// e.g. /** ...|
				// beforeText: ^\s*\/\*\*(?!\/)([^\*]|\*(?!\/))*$
				beforeText: new RegExp("^\\s*" + cbegin + "(?!"+ cend + ")([^" + cend1 + "]|" + cend1 + "(?!" + cend2 + "))*$"),
				action: { indentAction: vscode.IndentAction.None, appendText: strCommentPrefix }
			},
			{
				// e.g.  * ...|
				// beforeText: ^(\t|(\ \ ))*\ \*(\ ([^\*]|\*(?!\/))*)?$
				beforeText: new RegExp("^(\\t|(\\ ))(\\t|(\\ ))*" + cprefix + "(\\ " + "([^" + cend1 + "]|" + cend1 + "(?!" + cend2 + "))*)?$"),
				action: { indentAction: vscode.IndentAction.None, appendText: StringTools.ltrim(strCommentPrefix) }
			},
#if blap
			{
				// e.g.  */|
				// beforeText: ^(\t|(\ \ ))*\ \*\/\s*$
				beforeText: new RegExp("^(\\t|(\\ \\ ))*\\ \\*\\/\\s*$"),
				action: { indentAction: vscode.IndentAction.None, removeText: 1 }
			},
			{
				// e.g.  *-----*/|
				// beforeText: ^(\t|(\ \ ))*\ \*[^/]*\*\/\s*$
				beforeText: new RegExp("^(\\t|(\\ \\ ))*\\ \\*[^/]*\\*\\/\\s*$"),
				action: { indentAction: vscode.IndentAction.None, removeText: 1 }
			}
#end					
		];
		CodeDox.log("onEnter rules for " + settings.strLanguage + ":");
		CodeDox.log(onEnterRules);
		return onEnterRules;
	}

} // end of EnterRules class