# Changelog

## Unreleased

- Raise the minimum supported Ruby version to 3.3.
- Normalize core construction sizes consistently and validate size and block
  index before requesting default entropy. Accept frozen explicit state strings.
- Treat entropy and adjustments as bytes regardless of string encoding, while
  preserving caller strings and existing ASCII/binary output sequences.
- Preserve generator state on invalid adjustment input and preserve existing
  modifiers when conversion fails, including whole `modify_next` batches.
