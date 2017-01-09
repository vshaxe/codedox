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
import vscode.QuickPickItem;
import wiggin.codedox.License;
import wiggin.util.ConfigUtil;
import wiggin.util.StructUtil;
import wiggin.util.StringUtil;

typedef Transaction = {scope:Scope, obj:{}}

/**
 *  Implements command for setting up minimal config.
 */
class Setup
{
	/** Collects config changes so they can be applied (or aborted) at the end of the wizard. */
	private var m_transaction:Transaction;

	/**
	 *  Constructor
	 */
	public function new()
	{
		m_transaction = {scope:Scope.USER, obj:{}};
	}

	/**
	 *  Run the setup "wizard".
	 */
	public function doSetup() : Promise<Bool>
	{
		return new Promise(function(resolve,reject) {
			pickScope()
			.then(pickDefaultLicense)
			.then(inputCompany)
			.then(applyConfig)
			.then(resolve,function(err){
				if(err != null && Std.string(err) == "")
				{
					Vscode.window.showInformationMessage("Setup cancelled.");
					reject("");
				}
			});
		});
	}

	/**
	 *  Allows the user to select whether settings are written to USER or WORKSPACE config.
	 *  @return Promise<Bool>
	 */
	private function pickScope() : Promise<Bool>
	{
		var prom = new Promise(function(resolve,reject){
			var item1:QuickPickItem = {label:Scope.USER, description:"Stored globally, applies to any instance of VS Code"};
			var item2:QuickPickItem = {label:Scope.WORKSPACE, description:"Stored inside current workspace in the .vscode folder"};
			
			if(Vscode.workspace.rootPath == null)
			{
				// Can only write to USER when no folder opened.
				m_transaction.scope = Scope.USER;
				resolve(true);
			}
			Vscode.window.showQuickPick([item1, item2], {placeHolder:"Where should these settings be stored?"}).then(
				function(item)
				{
					if(item != null)
					{
						m_transaction.scope = (item.label == Scope.USER) ? Scope.USER : Scope.WORKSPACE;
						resolve(true);
					}
					else
					{
						reject("");
					}
				},
				function(err)
				{
					reject(err);
				}
			);
		});
		return prom;
	}

	/**
	 *  Allows the user to select a default license.
	 *  @return Promise<Bool>
	 */
	private function pickDefaultLicense(Void) : Promise<Bool>
	{
		var prom = new Promise(function(resolve,reject) {
			// Create list of available built-in licenses.
			var arr:Array<License> = getDefaultLicenses();
			var items:Array<QuickPickItem> = [];
			for(license in arr)
			{
				items.push({label:license.description, description:license.name});
			}
			Vscode.window.showQuickPick(items, {placeHolder:"Select a default license"}).then(
				function(item)
				{
					if(item != null)
					{
						var str = "${" + item.description + "}";
						var update = {fileheader:{templates:{"*":[str]}}};
						m_transaction.obj = StructUtil.mergeStruct(m_transaction.obj, update);
						resolve(true);
					}
					else
					{
						reject("");
					}
				},
				function(err)
				{
					reject(err);
				}
			);
		});
		return prom;
	}

	/**
	 *  Allows the user to enter a company name.
	 *  @return Promise<Bool>
	 */
	private function inputCompany(Void) : Promise<Bool>
	{
		var prom = new Promise(function(resolve,reject){
			var strCompany = getCurrentCompany();
			Vscode.window.showInputBox({prompt:"Enter your company or author name", value:strCompany}).then(
				function(strInput)
				{
					if(StringUtil.hasChars(strInput))
					{
						var update = {fileheader:{params:{"*":{company:strInput}}}};
						m_transaction.obj = StructUtil.mergeStruct(m_transaction.obj, update);
						resolve(true);
					}
					else
					{
						reject("");
					}
				},
				function(err)
				{
					reject(err);
				}
			);
		});
		return prom;
	}

	/**
	 *  Update's user's config with the specified company name.
	 *  @param strCompany - text to save in the `company` property
	 *  @return Promise<Bool>
	 */
	private function applyConfig(Void) : Promise<Bool>
	{
		var prom = new js.Promise(function(resolve,reject) {
			var config = Vscode.workspace.getConfiguration();
			ConfigUtil.update(config, CodeDox.EXTENSION_NAME, m_transaction.obj, m_transaction.scope).then(
				function(Void)
				{
					#if debug
					trace(CodeDox.EXTENSION_NAME + "Config updated successfully.");
					#end

					resolve(true);
				}, 
				function(reason)
				{
					#if debug
					trace("Failed to update " + CodeDox.EXTENSION_NAME + " config.");
					trace(reason);
					#end

					var str = (m_transaction.scope == Scope.USER) ? "user settings.json" : "workspace settings.json";
					reject('Error updating config. Check for errors in your ${str} and try again.');
				}
			);
		});
		return prom;
	}

	/**
	 *  Reads the default license definitions from a file.
	 *  @return Array<License>
	 */
	public static function getDefaultLicenses() : Array<License>
	{
		var str = sys.io.File.getContent(CodeDox.getExtPath() + "/defaultlicenses.json");
		var arr:Array<License> = haxe.Json.parse(str);
		return arr;
	}

	/**
	 *  Returns the current value of the `company` property, or empty string if
	 *  not defined.
	 *  @return String or ""
	 */
	private static function getCurrentCompany() : String
	{
		var config = Vscode.workspace.getConfiguration();
		var strCompany= null;
		var editor = Vscode.window.activeTextEditor;
		if(editor == null)
		{
			strCompany = config.get(FileHeader.PARAMS + "." + editor.document.languageId + ".company", null);
		}
		
		if(strCompany == null)
		{
			strCompany = config.get(FileHeader.PARAMS + ".*.company", "");
		}
		return strCompany;
	}

} // end of Setup class