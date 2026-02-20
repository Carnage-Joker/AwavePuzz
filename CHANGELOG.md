# Changelog

All notable changes to the AwavePuzz project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **[2026-01-30] Documentation Consolidation (Phase 2)**: Consolidated 90+ root-level documentation files into 7 organized docs/ files
  - Created `docs/BUG_FIXES.md` – consolidates 28 bug fix summaries, security hardening, and unfixable bugs records
  - Created `docs/AUDITS.md` – consolidates 20 audit reports, findings, checklists, and production readiness assessments
  - Created `docs/IMPLEMENTATION_HISTORY.md` – consolidates 18 implementation summaries, refactor histories, and architecture notes
  - Created `docs/TESTING_GUIDE.md` – consolidates existing testing guides, test plans, and validation reports
  - Created `docs/PR_HISTORY.md` – consolidates 4 pull request summary files
  - Created `docs/BOOT_SYSTEM.md` – consolidates 5 boot flow, safety guide, and flow diagram files
  - Created `docs/ANIMATIONS.md` – consolidates 4 animation guide, quick reference, checklist, and weapon animation files
  - Deleted 90 source files from root (all content preserved in consolidated docs/)
  - Also deleted `New Text Document.txt` and `REMOTE_EVENTS_NAMES_ONLY.txt`
  - Merged 13 additional loose docs/ files (BOOT_FLOW_FIXES_SUMMARY, BASE_DAMAGE_THROTTLING, VERIFICATION_SUMMARY, REMOTE_AUDIT, etc.) into their appropriate consolidated chapters
  - Updated `DOCUMENTATION.md` to version 5.0 reflecting fully consolidated structure
  - Fixed broken README.md links to point to consolidated files
- **[2026-01-29] Documentation Consolidation (Phase 1)**: Cleaned up and reorganized project documentation
  - Archived 42 historical documentation files to `docs/archive/` directory
  - Removed outdated `docs/STRUCTURE_OLD.md`
  - Updated `INSTALLATION.md` to reflect current repository structure (removed all `src/` references)
  - Created `docs/archive/README.md` to explain archived documentation
  - Updated `DOCUMENTATION.md` index with new structure
  - Updated `.github/copilot-instructions.md` to reflect current structure
  - Consolidated documentation from 86 total files to 18 essential root-level docs plus 38 supporting docs in `docs/`
  - All archived documentation preserved for historical reference in organized categories: fixes, summaries, reviews, reports

### Documentation Structure
After consolidation:
- **Root Level**: 18 essential documentation files
- **docs/features/**: 6 feature documentation files
- **docs/implementation/**: 4 implementation documentation files
- **docs/testing/**: 2 testing guide files
- **docs/archive/**: 42 historical documentation files (organized by category)

---

## Previous Releases

Documentation for previous releases and development history can be found in:
- `docs/archive/summaries/` - Historical implementation summaries
- `docs/archive/reviews/` - Project reviews and assessments
- `docs/archive/reports/` - Development reports and audits

---

**Note**: This CHANGELOG was created on 2026-01-29 as part of the documentation consolidation effort. Historical changes are documented in the archived files.
