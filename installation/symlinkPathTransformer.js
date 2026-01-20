#!/usr/bin/env node

/**
 * Transforms symlink filenames to their destination paths
 *
 * Format: {name}.{path}.symlink[.{extension}]
 * - DOT in path represents a dot (for hidden directories)
 * - Dots between path components become slashes
 *
 * Examples:
 *   CLAUDE.home.DOTclaude.symlink.md -> ~/.claude/CLAUDE.md
 *   zshrc.home.symlink -> ~/.zshrc
 *   init.lua.home.DOTconfig.symlink -> ~/.config/init.lua
 */

function transformPath(filename, homeDir) {
  // Check if file has extension after .symlink
  const hasExtension = /\.symlink\./.test(filename);

  if (hasExtension) {
    return transformWithExtension(filename, homeDir);
  } else {
    return transformWithoutExtension(filename, homeDir);
  }
}

function transformWithExtension(filename, homeDir) {
  // Extract extension (everything after .symlink.)
  const extensionMatch = filename.match(/\.symlink\.(.+)$/);
  if (!extensionMatch) return null;

  const extension = extensionMatch[1];
  const baseFilename = filename.replace(/\.symlink\..+$/, '');

  // Pattern: filename.home.SUBDIR.symlink.ext -> ~/.SUBDIR/filename.ext
  if (baseFilename.includes('.home.')) {
    const parts = baseFilename.split('.home.');
    const name = parts[0];
    const pathPart = parts[1];

    const transformedPath = transformPathComponent(pathPart);
    return `${homeDir}/${transformedPath}/${name}.${extension}`;
  }

  // Pattern: filename.home.symlink.ext -> ~/.filename.ext
  if (baseFilename.endsWith('.home')) {
    const name = baseFilename.replace(/\.home$/, '');
    return `${homeDir}/.${name}.${extension}`;
  }

  return null;
}

function transformWithoutExtension(filename, homeDir) {
  // Pattern: filename.home.SUBDIR.symlink -> ~/.SUBDIR/filename
  if (filename.match(/\.home\..+\.symlink$/)) {
    const baseFilename = filename.replace(/\.symlink$/, '');
    const parts = baseFilename.split('.home.');
    const name = parts[0];
    const pathPart = parts[1];

    const transformedPath = transformPathComponent(pathPart);
    return `${homeDir}/${transformedPath}/${name}`;
  }

  // Pattern: filename.home.symlink -> ~/.filename
  if (filename.endsWith('.home.symlink')) {
    const name = filename.replace(/\.home\.symlink$/, '');
    return `${homeDir}/.${name}`;
  }

  return null;
}

function transformPathComponent(pathPart) {
  // Replace DOT with a placeholder first
  let result = pathPart.replace(/DOT/g, '___DOT___');

  // Replace remaining dots with slashes (path separators)
  result = result.replace(/\./g, '/');

  // Replace placeholder with actual dots
  result = result.replace(/___DOT___/g, '.');

  return result;
}

// CLI usage
if (require.main === module) {
  const filename = process.argv[2];
  const homeDir = process.env.HOME || process.argv[3];

  if (!filename) {
    console.error('Usage: symlinkPathTransformer.js <filename> [homeDir]');
    process.exit(1);
  }

  const result = transformPath(filename, homeDir);

  if (result) {
    console.log(result);
    process.exit(0);
  } else {
    console.error(`Could not parse filename: ${filename}`);
    process.exit(1);
  }
}

module.exports = { transformPath };
