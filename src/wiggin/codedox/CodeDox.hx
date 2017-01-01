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
import vscode.ExtensionContext;
import vscode.TextEditor;
import vscode.TextEditorEdit;
import vscode.TextDocumentChangeEvent;
import vscode.TextLine;
import vscode.Selection;
import wiggin.codedox.FileHeader;
import wiggin.codedox.Commenter;
import wiggin.util.StringUtil;
import wiggin.util.ParseUtil;

typedef Settings = {autoInsert:Bool, strCommentBegin:String, strCommentEnd:String, 
					strCommentPrefix:String, strCommentDescription:String, strCommentTrigger:String, 
					strAutoClosingClose:String, strHeaderBegin:String, strHeaderEnd:String, strHeaderPrefix:String,
					strHeaderTrigger:String, }

/**
 *  Main extension class.
 *  - exports the `activiate` method
 *  - registers commands
 *  - provides command callbacks
 */
class CodeDox
{
	/** Extension name */
	public static inline var EXTENSION_NAME = "codedox";

	/** Fileheader feature */
	public static inline var FEATURE_FILEHEADER = EXTENSION_NAME + ".fileheader";

	/** Comment feature */
	public static inline var FEATURE_COMMENT = EXTENSION_NAME + ".comment";

	/** Command name for insert file header */
	public static inline var CMD_INSERT_FILE_HEADER = FEATURE_FILEHEADER + ".insert";

	/** Command name for insert comment */
	public static inline var CMD_INSERT_COMMENT = FEATURE_COMMENT + ".insert";

	/** Settings, lazy fetched */
	private static var s_settings:Settings = null;

	/** FileHeader inserter, lazy initialized */
	private var m_fileHeader:FileHeader;

	/** Commenter, lazy initialized */
	private var m_commenter:Commenter;

	/**
	 *  Constructor
	 */
	public function new(context:ExtensionContext)
	{
		m_fileHeader = null;
		m_commenter = null;

		context.subscriptions.push(Vscode.workspace.onDidChangeConfiguration(function(Void){s_settings=null;}));
		context.subscriptions.push(Vscode.workspace.onDidChangeTextDocument(onTextChange));

		registerTextEditorCommand(context, CMD_INSERT_FILE_HEADER, insertFileHeader);
		registerTextEditorCommand(context, CMD_INSERT_COMMENT, insertComment);

		// Add onEnter rules.
		var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration(EXTENSION_NAME);
		var bAutoPrefixOnEnter = config.get("autoPrefixOnEnter", false);
		var strCommentPrefix = config.get("commentprefix", "*  ");
		if(bAutoPrefixOnEnter)
		{
			Vscode.languages.setLanguageConfiguration("haxe", 
			{
				// TODO: modify these regex to use settings.strCommentBegin, settings.strCommentEnd, etc
				onEnterRules: [
					{				
						// e.g. /** | */
						beforeText: new js.RegExp("^\\s*\\/\\*\\*(?!\\/)([^\\*]|\\*(?!\\/))*$"),
						afterText: new js.RegExp("^\\s*\\*\\/$"),
						action: { indentAction: vscode.IndentAction.IndentOutdent, appendText: " " + strCommentPrefix }
					},
					{
						// e.g. /** ...|
						beforeText: new js.RegExp("^\\s*\\/\\*\\*(?!\\/)([^\\*]|\\*(?!\\/))*$"),
						action: { indentAction: vscode.IndentAction.None, appendText: " " + strCommentPrefix }
					},
					{
						// e.g.  * ...|
						beforeText: new js.RegExp("^(\\t|(\\ \\ ))*\\ \\*(\\ ([^\\*]|\\*(?!\\/))*)?$"),
						action: { indentAction: vscode.IndentAction.None, appendText: strCommentPrefix }
					},
					{
						// e.g.  */|
						beforeText: new js.RegExp("^(\\t|(\\ \\ ))*\\ \\*\\/\\s*$"),
						action: { indentAction: vscode.IndentAction.None, removeText: 1 }
					},
					{
						// e.g.  *-----*/|
						beforeText: new js.RegExp("^(\\t|(\\ \\ ))*\\ \\*[^/]*\\*\\/\\s*$"),
						action: { indentAction: vscode.IndentAction.None, removeText: 1 }
					}
				]
			});
		}
	}

	/**
	 *  Exported `activate` method called when the command is first activated.
	 *  @param context - the `ExtensionContext` provided by vscode. 
	 */
	@:expose("activate")
	static function activate(context:ExtensionContext)
	{
		new CodeDox(context);
	} 

	/**
	 *  Registers a command with vscode such that the `callback` will get
	 *	called whenever the command is executed. 
	 *	
	 *  @param strCmd - the command name as it appears in `package.json`
	 *	@param callback - the method called when the command is executed 
	 */
	private function registerTextEditorCommand(context:ExtensionContext, strCmd:String, callback:TextEditor->TextEditorEdit->Void)
	{
		var disposable = Vscode.commands.registerTextEditorCommand(strCmd, callback);
		context.subscriptions.push(disposable);
	}

	/**
	 *  Implementation of the `codedox.fileheader.insert` command.
	 */
	private function insertFileHeader(editor:TextEditor, edit:TextEditorEdit) : Void
	{
		try
		{
			if(m_fileHeader == null)
			{
				m_fileHeader = new FileHeader();
			}
			m_fileHeader.insertFileHeader(null, editor, edit);
		}
		catch(e:Dynamic)
		{
			handleError("Exception caught inserting file header: ", e, haxe.CallStack.exceptionStack());
		}
	}

	/**
	 *  Implementation of the `codedox.comment.insert` command.
	 */
	private function insertComment(editor:TextEditor, edit:TextEditorEdit) : Void
	{
		try
		{
			if(m_commenter == null)
			{
				m_commenter = new Commenter();
			}

			// Don't overwrite a non-empty line. Find previous blank line or insert one.
			var doc = editor.document;
			var pos = ParseUtil.findPrevBlankLine(editor, editor.selection.active);
			var line:TextLine = doc.lineAt(pos);

			m_commenter.insertComment(line, editor, edit);
		}
		catch(e:Dynamic)
		{
			handleError("Exception caught inserting comment: ", e, haxe.CallStack.exceptionStack());
		}
	}

	/**
	 *  Called whenever the text of the active document is changed. Here we decide if 
	 *  we should automatically insert a comment.
	 *  @param evt - the `TextDocumentChangeEvent`
	 */
	function onTextChange(evt:TextDocumentChangeEvent) : Void
	{
		try
		{
			// Vast majority of keystrokes will not result in an insert, so try to exit fast.
			var settings:Settings = getSettings();
			var doc = evt.document;
			if(!settings.autoInsert || !isLangaugeSupported(doc.languageId) || evt.contentChanges.length != 1)
			{
				return;
			}

			var editor = Vscode.window.activeTextEditor;
			if(editor.document != doc)
			{
				return;
			}

			var change = evt.contentChanges[0];
			var strChangeText = change.text;

			if(StringUtil.hasChars(strChangeText))
			{
				if(m_commenter != null && m_commenter.isInsertPending && strChangeText.indexOf(settings.strCommentDescription) != -1)
				{
					m_commenter.isInsertPending = false;
					var ft:FoundText = ParseUtil.findText(doc, change.range.start, settings.strCommentDescription);
					if(ft != null)
					{
						var sel:Selection = new Selection(ft.posEnd, ft.posStart);
						editor.selection = sel;
					}
				}
				else if(strChangeText == settings.strHeaderTrigger && doc.offsetAt(change.range.end) == 1 && change.range.isEmpty)
				{
					var line = doc.lineAt(0);
					if(line.text == settings.strHeaderBegin)
					{
						//js.Node.setTimeout(function() { doHeaderInsert(line, editor); }, 0);
						doHeaderInsert(line, editor);
					}  
				}
				else if(strChangeText == settings.strCommentTrigger || strChangeText == settings.strCommentTrigger + settings.strAutoClosingClose)
				{
					var line = doc.lineAt(change.range.start.line);
					var strCheck = StringUtil.trim(line.text);
					if(strCheck == settings.strCommentBegin || strCheck == settings.strCommentBegin + settings.strAutoClosingClose)
					{
						//js.Node.setTimeout(function() { doCommentInsert(line, editor); }, 0);
						doCommentInsert(line, editor);
					}
				}
			}
		}
		catch(e:Dynamic)
		{
			handleError("Exception caught `onTextChange`: ", e, haxe.CallStack.exceptionStack());
		}
	}

	/**
	 *  Inserts a file header triggered by keystrokes ("/*"). 
	 *
	 *  @param line - the `TextLine` to be replaced
	 *  @oaram editor - the `TextEditor` to modify
	 */
	private function doHeaderInsert(line:TextLine, editor:TextEditor) : Void
	{
		if(m_fileHeader == null)
		{
			m_fileHeader = new FileHeader();
		}

		editor.edit(function(edit:TextEditorEdit)
		{
			m_fileHeader.insertFileHeader(line, editor, edit);

		}, {undoStopBefore:false, undoStopAfter:true});
	}

	/**
	 *  Inserts a comment triggered by keystrokes ("/**").  The opening 
	 *  "/**" is deleted and replaced with a full comment.
	 *
	 *  @param line - the `TextLine` where the comment is to be inserted
	 *  @oaram editor - the `TextEditor` to modify
	 */
	private function doCommentInsert(line:TextLine, editor:TextEditor) : Void
	{
		if(m_commenter == null)
		{
			m_commenter = new Commenter();
		}

		editor.edit(function(edit:TextEditorEdit)
		{
			m_commenter.insertComment(line, editor, edit);

		}, {undoStopBefore:false, undoStopAfter:true});
	}

	/**
	 *  Reports an error.
	 *
	 *  @param strMsg - optional message
	 *  @param exp - optional exception
	 *  @param stack - optional stack trace
	 */
	private function handleError(strMsg:Null<String>, exp:Null<Dynamic>, stack:Null<Array<haxe.CallStack.StackItem>>) : Void
	{
		strMsg = StringUtil.hasChars(strMsg) ? strMsg : "";
		var strExp = (exp != null) ? Std.string(exp) : "";

		Vscode.window.showErrorMessage(strMsg + strExp);

		trace(strMsg + strExp);
		if(stack != null)
		{
			trace(haxe.CallStack.toString(stack));
		}
	}

	/**
	 *  Returns true if the language id is supported by this extension.
	 *  @param strLangId - the language id to check
	 @  @return Bool
	 */
	private inline function isLangaugeSupported(strLangId:String) : Bool
	{
		return switch(strLangId)
		{
			case "haxe": true;
			// TODO:  add additional languages here
			default: false;
		}
	}

	/**
	 *  Lazy fetches extension settings from config, caching the result so we don't have
	 *  to look this up each keystroke.
	 *  @return `Settings`
	 */
	public static function getSettings() : Settings
	{
		if(s_settings == null)
		{
			var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration(EXTENSION_NAME);
			var strCommentBegin = config.get("commentbegin", "/**");
			var strHeaderBegin = config.get("headerbegin", "/*");
			var strAutoClose = getAutoClosingClose(strCommentBegin);

			s_settings = {
				autoInsert: config.get("autoInsert", false),
				strCommentBegin: strCommentBegin,
				strCommentEnd: config.get("commentend", "*/"),
				strCommentPrefix: config.get("commentprefix", "*  "),
				strCommentDescription: config.get("commentdescription", ""),
				strCommentTrigger: StringUtil.right(strCommentBegin, 1),
				strAutoClosingClose: (strAutoClose != null) ? strAutoClose : "",
				strHeaderBegin: config.get("headerbegin", "/*"),
				strHeaderEnd: config.get("headerend", "*/"),
				strHeaderPrefix: config.get("headerprefix", " *"),
				strHeaderTrigger: StringUtil.right(strHeaderBegin, 1)
			};
		}
		return s_settings;
	}

	/**
	 *  Returns the autoclosing close string for the specified opening string.
	 *  e.g. "\**" is usually closed with "*\".
	 *  
	 *  @param strAutoClosingOpen - the opening string of an autoclosing pair
	 *  @return String or null
	 */
	private static function getAutoClosingClose(strAutoClosingOpen:String) : Null<String>
	{
		// Dammit. Vscode won't let me lookup the LanguageConfiguration settings.
		// Maybe this will be added in the future: https://github.com/Microsoft/vscode/issues/2871

		//var config:WorkspaceConfiguration = Vscode.workspace.getConfiguration();
		//var arr = config.get("haxe.configuration.autoClosingPairs", ["empty"]);

		// We'll have to hack something for now...
		return switch(strAutoClosingOpen)
		{
			// For some reason the Haxe extension configures vscode to autoclose with double asterisk.
			case "/**": "**/";  

			// Just reverse the open until we can read the real value??
			default: StringUtil.reverse(strAutoClosingOpen);  
		}
	}

} // end of CodeDox class