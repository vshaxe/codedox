# Codedox change log

## 1.2.4

* New config option `alwaysMultiline:boolean`. If true then all comments are multiline, otherwise non-functions (types) are single line
* OnEnter rules dynamically generated for custom configs
* Fix [issue 12](https://github.com/wiggin77/codedox/issues/12) Spaces added for non-function docs
* Fix [issue 10](https://github.com/wiggin77/codedox/issues/10) "commentend" & "commentprefix" have hardcoded space
* Fix [issue 8](https://github.com/wiggin77/codedox/issues/8) Params using type inference not handled properly
* Prepare for additional languages

## 1.2.3

* Fix "window.activeTextEditor can be null" via [Gamma11 PR](https://github.com/wiggin77/codedox/pull/5)
* Fix [issue 4](https://github.com/wiggin77/codedox/issues/4) Debug output in release
* Fixed README typos

## 1.2.2

* Fix [issue 3](https://github.com/wiggin77/codedox/issues/3) - determine if indentation should use tabs based on function being documented, not `editor.insertSpaces`
* Added option to include/remove the '?' prefix for optional function args in @param tags

## 1.2.1
* Allow customizable formats for @param and @return tags. [issue 1](https://github.com/wiggin77/codedox/issues/1)

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
- Initial submission to VS Code Marketplace