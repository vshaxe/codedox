# Codedox TODO

## Some todo's and bugs that I won't bother creating issues for

- (DONE)  Setup.applyConfig: filter out top-level properties of the wrong scope.
- (FIXED) Setup saving to USER overwrites existing params in USER; same for WORKSPACE.
- (DONE)  When populating template, merge params from "*" and "haxe" such that haxe overrides "*".
- (DONE)  Handle /** better for non-function comment --> end up with something like "\** | *\" 
- (FIXED) After setup wizard trigger by /* the re-running of cmd insert_file_header fails.
			- only when writing to WORKSPACE settings; the new data is not available
          	  until approx 1 sec delay (machine specific?), even though we wait for
              the promise to resolve.
- (DONE)  Handle */ and **/ auto close brackets; Haxe uses **/ for some reason

- When preceeding a class or abstract declaration , create empty multi-line JSDoc.
	- add option for single or multiline doc for vars

- Change comment "Description" to "Constructor" for function named "new"

- Support @extends and @implements for type comments
