# PGM security review — beta 3

## Scope

Reviewed PGM's Linux installer, local variant generator, native C hook, three Workshop Lua scripts and two Linux DFHack helper scripts. The current public release asset hashes are compared with the local archives used for review. Third-party mods, DFHack itself, DF-FR and the operating system are outside this code review.

## Confirmed issues and changes

| Area | Issue | Correction |
| --- | --- | --- |
| Linux restore metadata | A modified state could name unmanaged files or redirect backup reads. | Exact managed-file list, validated backup identifier, hashes and permissions. Backup paths use the same checks as targets. |
| File paths | Symbolic links in parent directories were insufficiently checked. | Reject links throughout managed paths, including state, lock and backup paths. Linux lock creation also uses O_NOFOLLOW. |
| Variant generation | Copying a linked source file could include data from outside the original mod. | Reject symbolic links, special files and Windows reparse points in source and existing destination trees. |
| Native game updates | Fixed-address reads occurred before an internal version check. The installer check alone did not protect subsequent game updates. | Native GNU build-ID check before patching the supported Linux executable. Other builds leave native translation disabled. |
| Native log files | Log creation followed a symbolic link. | Log opens use O_NOFOLLOW, reject non-regular and hard-linked files, and use private initial permissions. |
| Native memory | Allocation failures and malformed or excessive fields could lead to invalid accesses or incorrect parser state. | Checked allocations, bounded dictionary fields and file size, strict model token parsing. Allocation failure terminates the process with an error rather than continuing with an invalid pointer. |
| Model matching | Ambiguous patterns could spend excessive time backtracking. | Per-match work budget with fallback when exhausted. |
| Code memory protections | Trampoline pages remained writable and executable. | Write the trampoline in writable memory, then mark it read/execute before use. Abort if restoring code-page permissions fails. |
| Key hint settings | Non-finite or fractional offsets could reach integer formatting and break the script. | Require representable integer offsets from both commands and settings files. |

The installer runs as the game owner and refuses root execution. Its integrity manifest detects accidental damage to package files. This manifest and the release checksums do not constitute a signature authenticating an independently modified archive.

## Lua findings

The reviewed PGM Lua scripts use fixed DFHack commands and local game files or DFHack's persistence API. No network client, shell command assembled from quest text, or dynamic evaluation of translation data was found. The quest reward definitions are part of the script. Their counts and item identifiers are not loaded as executable code from the translation dictionaries.

The three Workshop scripts pass Lua syntax checks. Source and Workshop staging copies are compared. The installer and corpus hashes are included in the package.

## Tests

- Python tests cover repeat installation, restoration, injected write failure, unrecognized executable, modified restore state, backup traversal, unmanaged-file restoration, user edits and symbolic links.
- Variant tests cover linked sources and linked destinations. Actual downloaded originals are used for a separate compatibility-generation check.
- C regression tests cover unterminated CSV fields, escaped quotes, excess model tokens, adjacent captures, bounded backtracking, oversized dictionaries, linked logs and safe initialization under an unsupported executable.
- C tests use UndefinedBehaviorSanitizer and bounds checks with trap instrumentation.
- The release hook is compiled with stack protection, FORTIFY, RELRO, immediate binding and a non-executable stack. The trampoline is changed to read/execute after construction.

The AddressSanitizer build could not link because the host runtime libraries were absent. This review therefore includes targeted native tests and source examination, with no claim of exhaustive heap-memory coverage. A complete fortress playthrough and independent security review remain pending.

## Older releases

Use beta 3 for the updated installers and rebuilt Linux hook. Beta 1 and beta 2 retain the earlier implementations and are historical snapshots. Workshop users receive the key-setting correction after the same Steam item is updated from the new upload folder.
