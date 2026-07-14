# Changelog

## Unreleased

### Added
- Added public `ImpChartController` for programmatic chart control without exposing internal engine types
- Added public controller snapshots and event APIs:
  `ChartViewportSnapshot`, `ChartVisibleRange`, `ChartSelectionSnapshot`, `ChartRenderSnapshot`, and `ChartEvent`
- Added public `ChartFollowLatestState` for explicit live-update UX observation
- Added initial package test foundation under `test/unit`, `test/widget`, and `test/contract`

### Changed
- Updated `ImpChart` and all factory constructors to accept an optional `controller` while preserving existing usage
- Added snapshot-based observation hooks on `ImpChart` for viewport/state/event monitoring
- Extracted chart padding logic into a reusable `PaddingResolver`
- Formalized preserve-context live-update UX with auto-follow near the latest candles and no forced scroll while detached in history
- Refactored `ChartPainter` into a delegate-based rendering shell while preserving existing visual behavior and public usage
- Reduced `ImpChart` widget responsibility by extracting pulse, gesture-session, and live-update affordance helpers

### Internal
- Introduced controller-side collaborators for state storage, command execution, live update handling, interaction state, and viewport policy
- Completed the internal migration toward a controller-centered architecture without breaking existing public widget calls
- Split rendering concerns into focused internal delegates for line, grid, axis labels, current price, ripple, and crosshair drawing

### Fixed
- Restored auto-follow behavior for live data updates while preserving user context when the chart is detached from the latest candles
- Hardened widget-side candle change detection for apps that mutate the same candle list instance in place
- Added the missing tap-to-latest `Live` affordance when live data arrives during detached historical viewing

### Tests
- Expanded controller and widget coverage for follow-latest thresholds, preserve-context updates, and in-place mutated list rebuilds

## 0.1.2

### Added
- Created `CONTRIBUTING.md` with project guidelines and PR process
- Added `CODE_OF_CONDUCT.md` (Contributor Covenant)
- Added `ARCHITECTURE.md` explaining engine-first design and rendering pipeline
- Improved README with Contributing and Stability & Versioning sections

### Documentation & Hygiene
- Marked internal classes in `lib/src/` as internal implementation details
- Enhanced example app with helpful comments for future contributors
- **No breaking changes** - Behavior and public APIs remain fully stable

## 0.1.1

### Fixed
- Resolved deprecated Matrix4 scaling API usage
- Fixed internal import issues and warnings
- Package description updated
- No public API changes

## 0.1.0

### Initial release
- High-performance trading chart engine for Flutter
- CustomPainter-based candlestick rendering
- Viewport-driven drawing (only visible data rendered)
- Cached price scale and coordinate mapping
- Pan, zoom, and double-tap gesture support
- Fully customizable chart style and layout
- Engine-first architecture (Data → Engine → Rendering)
