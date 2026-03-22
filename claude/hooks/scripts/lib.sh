#!/usr/bin/env bash
# Shared utilities for dotfiles-claude hook scripts.
# Source this file, don't execute it directly.

# Portable hostname (short form). Falls back gracefully on minimal systems.
get_hostname() {
  hostname -s 2>/dev/null || hostname 2>/dev/null || echo "unknown"
}
