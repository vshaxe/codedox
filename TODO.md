# Codedox TODO

## Some todo's and bugs that I won't bother creating issues for

- Setup.applyConfig: filter out top-level properties of the wrong scope.  (DONE)
- setup saving to USER overwrites existing params in USER; same for WORKSPACE (FIXED)

- when populating template, merge params from "*" and "haxe" such that haxe overrides "*".

- handle /** better for non-function comment --> end up with something like "\** | *\" 

- handle */ and **/ auto close brackets; Haxe uses **/ for some reason

- after setup wizard trigger by /* the re-running of cmd insert_file_header fails.
	- only when writing to WORKSPACE settings; the new data is not available
          until approx 1 sec delay (machine specific?), even though we wait for
          the promise to resolve.

