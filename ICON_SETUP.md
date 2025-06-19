# Icon Setup Instructions

To use your custom asterisk icon:

1. Save your icon image to this directory as `claudez-icon.png`

2. Run the icon processor:
   ```bash
   ./process-icon.sh claudez-icon.png
   ```

3. Rebuild the app with the new icon:
   ```bash
   ./build-app.sh
   ```

4. Create new package:
   ```bash
   ./create-pkg.sh
   ```

5. Copy the new package to releases:
   ```bash
   cp ClaudeZ-1.0.0.pkg releases/
   ```

6. Commit and push:
   ```bash
   git add -A
   git commit -m "Update with custom asterisk icon"
   git push
   ```

The icon processor will:
- Extract a single icon from the grid (top-left)
- Generate all required sizes for the app icon
- Create menu bar versions
- Package everything properly

Your asterisk icon will then appear in both the menu bar and as the app icon!