#!/usr/bin/env node

/**
 * Transforms symlink filenames to their destination paths
 *
 * Format: {name}.home[.{path}].symlink[.{extension}]
 * - DOT represents a literal dot (for hidden directories/files)
 * - Dots between path components become slashes
 * - Repository organization (which folder files are in) is ignored
 *
 * Examples:
 *   CLAUDE.home.DOTclaude.symlink.md -> ~/.claude/CLAUDE.md
 *   DOTzshrc.home.symlink -> ~/.zshrc
 *   init.lua.home.DOTconfig.symlink -> ~/.config/init.lua
 *   DOTconfig.home.symlink -> ~/.config
 */
function transformPath(filename, homeDir) {
  // Only support .home. pattern for now (files going to home directory)
  if (!filename.includes('.home')) {
    return null;
  }

  // Extract extension: everything after "symlink" (.md or empty string)
  const extension = filename.replace(/.*symlink/, '');

  // Get base filename by removing .symlink{extension}
  const base = filename.replace(/\.symlink.*$/, '');

  // Split on .home to get name and path parts
  const parts = base.split('.home');
  const name = parts[0].replace(/DOT/g, '.');
  const pathPart = parts[1] ? parts[1].substring(1) : '';  // Remove leading '.'

  // Build destination path
  const transformedPath = transformPathComponent(pathPart);
  return `${homeDir}${transformedPath}/${name}${extension}`;
}

function transformPathComponent(pathPart) {
  if (!pathPart) return '';
  // Replace . with / for path separators, then DOT with . for literal dots, add leading /
  return '/' + pathPart.replace(/\./g, '/').replace(/DOT/g, '.');
}

// CLI entry point
(function main() {
  const filename = process.argv[2];

  if (!filename) {
    console.error('Usage: symlinkPathTransformer.js <filename>');
    process.exit(1);
  }

  const result = transformPath(filename, process.env.HOME);

  if (result) {
    console.log(result);
  } else {
    console.error(`Could not parse filename: ${filename}`);
    process.exit(1);
  }
})();
