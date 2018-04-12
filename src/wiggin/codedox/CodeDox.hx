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

import js.Promise;
import vscode.ExtensionContext;
import vscode.TextEditor;
import vscode.TextEditorEdit;
import vscode.TextDocumentChangeEvent;
import vscode.TextDocumentContentChangeEvent;
import vscode.TextLine;
import vscode.Selection;
import vscode.Position;
import wiggin.codedox.FileHeader;
import wiggin.codedox.Commenter;
import wiggin.util.StringUtil;
import wiggin.util.ParseUtil;
using StringTools;
using Lambda;

typedef CheckAction = TextDocumentContentChangeEvent->Settings->TextEditor->Bool;

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

	/** Command name for setup */
	public static inline var CMD_SETUP = EXTENSION_NAME + ".setup";

	/** Command name for insert file header */
	public static inline var CMD_INSERT_FILE_HEADER = FEATURE_FILEHEADER + ".insert";

	/** Command name for insert comment */
	public static inline var CMD_INSERT_COMMENT = FEATURE_COMMENT + ".insert";

	/** Path to extension installation. **/
	private static var s_extPath:String = null;

	/** FileHeader inserter, lazy initialized */
	private var m_fileHeader:FileHeader;

	/** Commenter, lazy initialized */
	private var m_commenter:Commenter;

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
	 *  Constructor
	 */
	public function new(context:ExtensionContext)
	{
		m_fileHeader = null;
		m_commenter = null;
		s_extPath = context.extensionPath;

		context.subscriptions.push(Vscode.workspace.onDidChangeConfiguration(function(Void){Settings.clearCache(); applyOnEnterRules(context);}));
		context.subscriptions.push(Vscode.workspace.onDidChangeTextDocument(onTextChange));

		registerCommand(context, CMD_SETUP, doSetup);
		registerTextEditorCommand(context, CMD_INSERT_FILE_HEADER, insertFileHeader);
		registerTextEditorCommand(context, CMD_INSERT_COMMENT, insertComment);

		applyOnEnterRules(context);
	}

	/**
	 *  Add onEnter rules for all supported languages.
	 *  @param context - the `ExtensionContext`
	 */
	private function applyOnEnterRules(context:ExtensionContext) : Void
	{
		for(strLang in Settings.getSupportedLanguages())
		{
			var settings = Settings.fetch(strLang);
			if(settings.autoPrefixOnEnter && settings.strCommentPrefix.trim().length > 0)
			{
				var rules = EnterRules.createRules(settings);
				var disposable = Vscode.languages.setLanguageConfiguration(strLang, {onEnterRules:rules});
				context.subscriptions.push(disposable);
			}
		}
	}

	/**
	 *  Registers a command with vscode such that the `callback` will get
	 *	called whenever the command is executed. 
	 *	
	 *  @param strCmd - the command name as it appears in `package.json`
	 *	@param callback - the method called when the command is executed 
	 */
	private function registerCommand(context:ExtensionContext, strCmd:String, callback:Void->Void)
	{
		var disposable = Vscode.commands.registerCommand(strCmd, callback);
		context.subscriptions.push(disposable);
	}

	/**
	 *  Registers a text editor command with vscode such that the `callback` will get
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
	 *  Implementation of the `codedox.setup` command.
	 *  @returns Promise<Bool> - a Thenable that resolves to true if setup completed successfully.
	 */
	private function doSetup() : Promise<Bool>
	{
		var prom:Promise<Bool>;
		try
		{
			var setup = new Setup();
			prom = setup.doSetup();
			prom.catchError(
				function(err)
				{
					handleError(err, null, null);
				}
			);
		}
		catch(e:Dynamic)
		{
			handleError("Error setting up minimal config: ", e, haxe.CallStack.exceptionStack());
			prom = Promise.reject();
		}
		return prom;
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
			handleError("Error inserting file header: ", e, haxe.CallStack.exceptionStack());
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
			handleError("Error inserting comment: ", e, haxe.CallStack.exceptionStack());
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
			var doc = evt.document;
			if(!isLanguageSupported(doc.languageId) || evt.contentChanges.length != 1)
			{
				return;
			}

			var editor = Vscode.window.activeTextEditor;
			if(editor == null || editor.document != doc)
			{
				return;
			}

			var settings:Settings = Settings.fetch(doc.languageId);
			if(!settings.autoInsert && !settings.autoInsertHeader)
			{
				return;
			}

			var change = evt.contentChanges[0];
			if(StringUtil.hasChars(change.text))
			{
				var arr:Array<CheckAction> = [checkInsertPending, checkInsertHeader, checkInsertComment];
				arr.foreach(function(fn) {return !fn(change, settings, editor);});
			}
		}
		catch(e:Dynamic)
		{
			handleError("", e, haxe.CallStack.exceptionStack());
		}
	}

	/**
	 *  Checks if the `TextDocumentContentChangeEvent` requires "insert-pending" handling, meaning an insert is pending
	 *  and we need to reposition the cursor.
	 *  
	 *  @param change - the `TextDocumentContentChangeEvent` 
	 *  @param settings - the current `Settings` object 
	 *  @param editor - the current `TextEditor` object
	 *  @return Bool - true if the event was processed
	 */
	private function checkInsertPending(change:TextDocumentContentChangeEvent, settings:Settings, editor:TextEditor) : Bool
	{
		var bRet = false;
		var strChangeText = change.text;
		var doc = editor.document;

		if(m_commenter != null && m_commenter.isInsertPending && strChangeText != null)
		{
			bRet = true;

			// A comment insert was just performed and we need to put the cursor in the right place, and possibly
			// select a comment description so the user can just start typing to overwrite it.
			m_commenter.isInsertPending = false;
			var strDescription = StringUtil.trim(settings.strCommentDescription);
			var i = strDescription.indexOf("\n");
			strDescription = (i != -1) ? strDescription.substring(0, i) : strDescription;
			if(!StringUtil.onlyWhitespace(strDescription) && strChangeText.indexOf(strDescription) != -1)
			{
				// Select the "Description" text.
				var ft:FoundText = ParseUtil.findText(doc, change.range.start, strDescription);
				if(ft != null)
				{
					editor.selection = new Selection(ft.posEnd, ft.posStart);
				}
			}
			else if(strChangeText.indexOf(settings.strCommentToken) != -1)
			{
				// Multiline comment for a type. Place cursor at token, then delete token.
				var ft:FoundText = ParseUtil.findText(doc, change.range.start, settings.strCommentToken);
				if(ft != null)
				{
					var p:Position = new Position(ft.posEnd.line, ft.posEnd.character + 1);
					editor.selection = new Selection(p, p);
					editor.edit(function(edit:TextEditorEdit)
					{
						edit.delete(new vscode.Range(ft.posStart, ft.posEnd));
					}, {undoStopBefore:false, undoStopAfter:false});
				}
			}
			else if(strChangeText.trim() == settings.strCommentBegin + " " + settings.strCommentEnd)
			{
				// Single line comment was added.  Position cursor 1 char after the comment begin.
				var ft:FoundText = ParseUtil.findText(doc, change.range.start, settings.strCommentBegin);
				if(ft != null)
				{
					var p:Position = new Position(ft.posEnd.line, ft.posEnd.character + 1);
					editor.selection = new Selection(p, p);
				}
			}
		}
		CodeDox.log("checkInsertPending: " + bRet);
		return bRet;
	}

	/**
	 *  Checks if the `TextDocumentContentChangeEvent` should trigger a header insert.
	 *  
	 *  @param change - the `TextDocumentContentChangeEvent` 
	 *  @param settings - the current `Settings` object 
	 *  @param editor - the current `TextEditor` object
	 *  @return Bool - true if the event was processed
	 */
	private function checkInsertHeader(change:TextDocumentContentChangeEvent, settings:Settings, editor:TextEditor) : Bool
	{
		var bRet = false;

		if(settings.autoInsertHeader && 
		   StringUtil.startsWith(change.text, settings.strHeaderTrigger) && 
		   change.range.end.line == 0 && 
		   change.range.isEmpty)
		{
			bRet = true;

			// A header comment trigger was typed at the top of file. 
			var line = editor.document.lineAt(0);
			var strLine = line.text;
			if(strLine == settings.strHeaderBegin || strLine == settings.strHeaderBegin + settings.strHeaderEnd)
			{
				doHeaderInsert(line, editor);
			}  
		}
		CodeDox.log("checkInsertHeader: " + bRet);
		return bRet;
	}

	/**
	 *  Checks if the `TextDocumentContentChangeEvent` should trigger a comment insert.  This could be
	 *  a function or type comment.
	 *  
	 *  @param change - the `TextDocumentContentChangeEvent` 
	 *  @param settings - the current `Settings` object 
	 *  @param editor - the current `TextEditor` object
	 *  @return Bool - true if the event was processed
	 */
	private function checkInsertComment(change:TextDocumentContentChangeEvent, settings:Settings, editor:TextEditor) : Bool
	{
		var bRet = false;
		var strChangeText = change.text;

		if(settings.autoInsert && strChangeText == settings.strCommentTrigger || 
		   strChangeText == settings.strCommentTrigger + settings.strAutoClosingClose ||
		   strChangeText == settings.strCommentTrigger + settings.strAutoClosingCloseAlt)
		{
			bRet = true;

			// A function comment trigger was typed.
			var line = editor.document.lineAt(change.range.start.line);
			var strCheck = StringUtil.trim(line.text);
			if(strCheck == settings.strCommentBegin || 
				strCheck == settings.strCommentBegin + settings.strAutoClosingClose ||
				strCheck == settings.strCommentBegin + settings.strAutoClosingCloseAlt)
			{
				doCommentInsert(line, editor);
			}
		}
		CodeDox.log("checkInsertComment: " + bRet);
		return bRet;
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

		}, {undoStopBefore:false, undoStopAfter:false});
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

		}, {undoStopBefore:false, undoStopAfter:false});
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

		if(StringUtil.hasChars(strMsg) || StringUtil.hasChars(strExp))
		{
			Vscode.window.showErrorMessage(strMsg + strExp);

			log(strMsg + strExp);
			if(stack != null)
			{
				log(haxe.CallStack.toString(stack));
			}
		}
	}

	/**
	 *  Logs message to console via trace.
	 *  @param msg - message to output
	 */
	public static function log(msg:Dynamic, ?pos:haxe.PosInfos) : Void
	{
		#if debug
		haxe.Log.trace(Std.string(msg), pos);
		#end
	}

	/**
	 *  Returns true if the language id is supported by this extension.
	 *  @param strLangId - the language id to check
	 *  @return Bool
	 */
	private static inline function isLanguageSupported(strLangId:String) : Bool
	{
		return Settings.getSupportedLanguages().indexOf(strLangId) != -1;
	}

	/**
	 *  Returns the language id for the current editor/document, or null if no 
	 *  editor/document is present.
	 *  @return String or null
	 */
	public static function getCurrentLanguageId() : Null<String>
	{
		var strLang:Null<String> = null;
		var editor = Vscode.window.activeTextEditor;
		if(editor != null && editor.document != null)
		{
			strLang = editor.document.languageId;
		}
		return strLang;
	}

	/**
	 *  Returns the full path where this extension is installed.
	 *  @return String - null if extension not yet activated
	 */
	public static function getExtPath() : String
	{
		return s_extPath;
	}


} // end of CodeDox class
