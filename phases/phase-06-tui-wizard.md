# Phase 6: TUI Wizard Enhancement

## Goal
Ensure the bootstrap wizard handles 3 packs correctly.

## Tasks
1. Verify pack_state.py list-packs discovers all 3 packs
2. Test that bootstrap-wizard.sh presents research-and-strategy as an option
3. Ensure profile comparison and summary work for the new pack

## Verification
- `python3 scripts/pack_state.py list-packs .` returns 3 packs
- No code changes needed if the wizard is already pack-generic (verify)
