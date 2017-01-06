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

import js.Promise.Thenable;
import vscode.WorkspaceConfiguration;
import vscode.QuickPickItem;
import wiggin.codedox.License;
import wiggin.util.ConfigUtil;

typedef Result = {success:Bool, exp:Dynamic}

/**
 *  Implements command for setting up minimal config.
 */
class Setup
{
	public function new()
	{
		// Do nothing.
	}

	/**
	 *  Run the setup "wizard".
	 */
	public function doSetup() : Thenable<Bool>
	{
		return new js.Promise(function(resolve,reject) {
			js.Promise.all([pickDefaultLicense(), inputCompany()]).then(
				function(arr)
				{
					var arrResults:Array<Bool> = arr;
					var bResult = true;
					for(res in arrResults) {if(!res) bResult = false;}
					resolve(bResult);
				},
				function(reason)
				{
					reject(reason);
				}
			);
		});
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
	 *  Allows the user to select a default license.
	 */
	private static function pickDefaultLicense() : Thenable<Bool>
	{
		var config = Vscode.workspace.getConfiguration();

		return new js.Promise(function(resolve,reject) {
			var arr:Array<License> = getDefaultLicenses();

			// Create list of available built-in licenses.
			var items:Array<QuickPickItem> = [];
			for(license in arr)
			{
				items.push({label:license.description, description:license.name});
			}

			Vscode.window.showQuickPick(items, {placeHolder:"Select a default license"}).then(function (item:QuickPickItem) {	
				if(item != null)
				{
					setDefaultTemplate(item.description, config).then(
						function(Void)
						{
							resolve(true);
						},
						function(reason)
						{
							reject(reason);
						}
					);	
				}
				else
				{
					resolve(false);
				}
			});
		});
	}

	/**
	 *  Updates the user's config with the specified default template.
	 *  @param strLicense - name of the built-in license param
	 *  @param config - the `WorkspaceConfiguration` to write to
	 */
	private static function setDefaultTemplate(strLicense:String, config:WorkspaceConfiguration) : Thenable<Bool>
	{
		return new js.Promise(function(resolve,reject){
			var str = "${" + strLicense + "}";
			var update = {fileheader:{templates:{"*":[str]}}};

			ConfigUtil.update(config, CodeDox.EXTENSION_NAME, update).then(
				function(Void)
				{
					#if debug
					trace(CodeDox.EXTENSION_NAME + "Default template set successfully.");
					#end

					resolve(true);
				}, 
				function(reason)
				{
					#if debug
					trace("Failed to set " + CodeDox.EXTENSION_NAME + " default template.");
					trace(reason);
					#end

					reject("Error writing config. Check for errors in your user settings.json and try again.");
				}
			);
		});
	}

	/**
	 *  Allows the user to enter a company name.
	 */
	private static function inputCompany() : Thenable<String>
	{
		return null;
	}
}