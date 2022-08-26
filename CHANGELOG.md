# Codedox change log

## 1.3.2

* fixed compatibility issue with vshaxe 2.24.x
* switched to Lix for dependency management

## 1.3.1

* replicate vshaxe onEnter rules as codedox overwrites them

## 1.3.0

* Update hxnodejs and node.js to fix warning "requires node.js version 4.0.0 or higher"
* Compile with Haxe 4.0.0rc1

## 1.2.9

* Revert to space prefixing comment body.

## 1.2.8

* Change default comment prefix and formatting to better display in vshaxe and Dox.

## 1.2.7

* Fixed broken indentation with a `commentprefix` that only contains whitespace; see [issue 26](https://github.com/vshaxe/codedox/issues/26)

## 1.2.6

* Added `fname`, `fspec`, `frel` parameters; see [issue 23](https://github.com/vshaxe/codedox/issues/23)
* Allow params in any part of method comment

## 1.2.5

* Travis-CI integraton
* New icon
* README edits

## 1.2.4

* Repo moved to [vshaxe](https://github.com/vshaxe) organization
* Fix [issue 16](https://github.com/vshaxe/codedox/issues/16) support newlines in comment description, paramFormat, returnFormat
* New config option `alwaysMultiline:true`. If true then all comments are multiline, otherwise non-functions (types) are single line
* OnEnter rules dynamically generated for custom configs
* Fix [issue 12](https://github.com/vshaxe/codedox/issues/12) Spaces added for non-function docs
* Fix [issue 10](https://github.com/vshaxe/codedox/issues/10) "commentend" & "commentprefix" have hardcoded space
* Fix [issue 8](https://github.com/vshaxe/codedox/issues/8) Params using type inference not handled properly
* Prepare for additional languages

## 1.2.3

* Fix "window.activeTextEditor can be null" via [Gamma11 PR](https://github.com/vshaxe/codedox/pull/5)
* Fix [issue 4](https://github.com/vshaxe/codedox/issues/4) Debug output in release
* Fixed README typos

## 1.2.2

* Fix [issue 3](https://github.com/vshaxe/codedox/issues/3) - determine if indentation should use tabs based on function being documented, not `editor.insertSpaces`
* Added option to include/remove the '?' prefix for optional function args in @param tags

## 1.2.1

* Allow customizable formats for @param and @return tags. [issue 1](https://github.com/vshaxe/codedox/issues/1)

## 1.2.0

* Setup wizard to create minimal config without editing settings.json by hand

* Include built-in file header license templates
  * GNU Affero General Public License
  * Apache License, Version 2.0
  * GNU General Public License, Version 3.0
  * MIT License
  * Mozilla Public License, Version 2.0
* Better support for non-function related comments
* Documentation added to [README.md](./README.md)
  * Built-in file header params
  * Built-in license templates

## 1.1.0

* Initial submission to VS Code Marketplace
