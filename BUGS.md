# ClaudeZ Known Issues & Bug Tracker

This file tracks known bugs, issues, and improvements needed in ClaudeZ.

## 🔴 Critical Issues

### Launch at Login Not Implemented
- **File**: PreferencesWindow.swift:78
- **Status**: TODO comment exists
- **Description**: The "Launch at login" checkbox saves the preference but doesn't actually implement the functionality
- **Impact**: Users expect the app to launch at login when enabled, but it doesn't

## 🟡 High Priority Issues

### Instance Counter Issues
- [x] **Instance limit triggered with closed instances** (Fixed in latest commit)
- [x] **Phantom instances showing when none are running** - Fixed by filtering out Claude Helper processes
  - Root cause: Claude uses multiple helper processes (GPU Helper, Renderer Helper, etc.)
  - Solution: Only count main Claude.app processes, skip anything in Frameworks or with "Helper" in path
  - Added "Force Refresh Instances" menu option as additional safeguard
  - Added debug logging to track what's being detected
- [ ] **No handling for Claude Desktop not installed** - App crashes/fails when Claude isn't installed
- [ ] **Hardcoded Claude path fallback** - Falls back to `/Applications/Claude.app` which may not exist

### Voice Typing Issues
- [ ] **No timeout for recordings** - Voice typing can run indefinitely
- [ ] **Window can be closed while recording** - Leaves recording session active
- [ ] **Force unwrap on contentView** - Line 146 could crash if window has no content view
- [ ] **No visual feedback for denied microphone permission**

## 🟠 Medium Priority Issues

### Error Handling
- [ ] **MCPManager config errors not shown to user** - Errors only printed to console
- [ ] **Voice recognition error 203 continues recording** - Should probably stop when no speech detected
- [ ] **Audio engine startup failures don't clean up properly** - Recognition request/task left dangling

### Performance
- [ ] **5-second refresh timer runs constantly** - Impacts battery life unnecessarily
- [ ] **CGWindowListCopyWindowInfo called frequently** - Expensive operation
- [ ] **Multiple array iterations in detectExistingInstances** - Could be optimized

### UI/UX
- [ ] **Multiple preference windows can be opened** - Should be singleton
- [ ] **Auto-recording starts without confirmation** - 0.3 second delay might surprise users
- [ ] **No way to close specific Claude instances** - Can only launch new ones
- [ ] **MCP changes require manual Claude restart** - Should offer to restart

## 🟢 Low Priority Issues

### Code Quality
- [ ] **Multiple hardcoded bundle IDs** - Should be centralized/configurable
- [ ] **Force unwrapping and chained optionals** - Could be more robust
- [ ] **Window ID detection assumes single window per process** - Doesn't handle multiple windows
- [ ] **Placeholder text detection is fragile** - String comparison could break

### Missing Features
- [ ] **No keyboard shortcuts beyond 1-9** - Limited to 9 instances
- [ ] **No validation of MCP server configs** - Could save invalid configurations
- [ ] **Toggle server name edge case** - Servers already starting with underscore

### Security/Privacy
- [ ] **No path validation for MCP config** - Could potentially open arbitrary files
- [ ] **No privacy indicator for speech recognition** - Only app's own UI

## 📝 Notes

### Fixed Issues
- ✅ **Instance counting fails with closed instances** - Fixed by adding termination observer and cleanup logic

### Workarounds in Code
- Bundle ID detection tries multiple variants due to inconsistent Claude naming
- Icon loading has multiple fallback attempts
- Claude app discovery tries bundle IDs, then names, then hardcoded path

## 🔧 How to Contribute

When fixing a bug:
1. Move it to "Fixed Issues" section with a checkmark
2. Note the commit/version where it was fixed
3. Remove from active issues list

When finding a new bug:
1. Add to appropriate priority section
2. Include file:line reference if applicable
3. Describe impact on users
4. Add any relevant workarounds