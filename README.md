# Codedox for Haxe and Visual Studio Code

This is an extension for [Visual Studio Code](https://code.visualstudio.com) that helps developers document their [Haxe](http://haxe.org/) code. 
JSDoc style comments can be inserted including automatic generation of `@param` and `@return` tags.  File headers can be inserted with customizable
copyright and license comments.

This extension is best used as a companion to [vshaxe](https://marketplace.visualstudio.com/items?itemName=nadako.vshaxe) which provides Haxe 
support for Visual Studio Code.

## Usage

1. Add Codedox settings to your workspace or user configuration. Cut and paste from sample [here](./sample.codedox.json).
2. Customize your copyright and license text. Sample MIT license included below.
3. Type `/*` at top of file to insert a file header.
4. Position cursor before a function declaration and type `/**` to insert a JSDoc-style comment.

File header and JSDoc-style comments can also be inserted using commands. Invoke the commands using `F1` or `Ctrl-Shift-P`/`Cmd-Shift-P` and 
typing `Codedox: Insert ...`

## Features

### Insert JSDoc comment
![Insert JSDoc comment](images/jsdoc-comment.gif)

### On-enter rules
![On-enter rules](images/on-enter-rules.gif)

### Insert file header
![Field completion](images/fileheader.gif)

## Configuration

Codedox supports the following settings. These can be cut and pasted into user or workspace settings file (`.vscode/settings.json`)
and customized as needed. The example below includes an MIT license:

```js
{
  "codedox": {
    "autoInsert": true,   		// Enables insertion trigged by keystrokes
    "autoPrefixOnEnter": true,		// Enables 'on enter' rules
    "commentprefix": "*  ",
    "commentbegin": "/**",
    "commentend": "*/",
    "commentdescription": "[Description]",
    "headerprefix": " *",
    "headerbegin": "/*",
    "headerend": " */",
    "fileheader": {
      "params": {
        "*": {
          "company": "My Company",
          "license_mit": [
            "${headerprefix} Copyright (c) ${year} ${company}",
            "${headerprefix}",
            "${headerprefix} Permission is hereby granted, free of charge, to any person obtaining a copy of",
            "${headerprefix} this software and associated documentation files (the \"Software\"), to deal in",
            "${headerprefix} the Software without restriction, including without limitation the rights to use,",
            "${headerprefix} copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the",
            "${headerprefix} Software, and to permit persons to whom the Software is furnished to do so,",
            "${headerprefix} subject to the following conditions:",
            "${headerprefix}",
            "${headerprefix} The above copyright notice and this permission notice shall be included in all",
            "${headerprefix} copies or substantial portions of the Software.",
            "${headerprefix}",
            "${headerprefix} THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR",
            "${headerprefix} IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS",
            "${headerprefix} FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR",
            "${headerprefix} COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN",
            "${headerprefix} AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH",
            "${headerprefix} THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
          ]
        }
      },
      "templates": {
        "*": [
          "${headerbegin}",
          "${license_mit}",
          "${headerend}"
        ]
      }
    }
  }
}
```

## Notes 
* If you do not want an asterisk preceding each line of a comment, replace the `commentprefix` property with `"  "`. 
* If you prefer only one space before each line of a comment, replace `commentprefix` with `"* "`. 
* Feature requests. comments, etc, welcome.

