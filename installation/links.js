#!/usr/bin/env bun

/**
 * Symlinking Logic for Dotfiles
 * Handles linking all .symlink files to their target locations
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const SCRIPT_DIR = __dirname;
const DOTFILES_ROOT = path.dirname(SCRIPT_DIR);
const LOGGING_SCRIPT = path.join(SCRIPT_DIR, 'logging.sh');

// Logging helpers
const log = {
  info: (msg) => execSync(`source "${LOGGING_SCRIPT}" && log_info '${msg}'`, { stdio: 'inherit', shell: '/bin/bash' }),
  success: (msg) => execSync(`source "${LOGGING_SCRIPT}" && log_success '${msg}'`, { stdio: 'inherit', shell: '/bin/bash' }),
  warn: (msg) => execSync(`source "${LOGGING_SCRIPT}" && log_warn '${msg}'`, { stdio: 'inherit', shell: '/bin/bash' }),
  error: (msg) => execSync(`source "${LOGGING_SCRIPT}" && log_error '${msg}'`, { stdio: 'inherit', shell: '/bin/bash' }),
};

// Path transformation logic (from symlinkPathTransformer.js)
const extractExtension = (filename) => filename.replace(/.*symlink/, '');
const removeSymlinkAndExtension = (filename) => filename.replace(/\.symlink.*$/, '');
const replaceDOTWithDot = (str) => str.replace(/DOT/g, '.');
const removeLeadingDot = (str) => str ? str.substring(1) : '';

const transformPathToDirectory = (pathPart) => pathPart ? '/' + pathPart.replace(/\./g, '/').replace(/DOT/g, '.') : '';

function transformPath(filename) {
  if (!/\.home/.test(filename)) return null;

  const extension = extractExtension(filename);
  const base = removeSymlinkAndExtension(filename);
  const [namePart, ...rest] = base.split('.home');
  const name = replaceDOTWithDot(namePart);
  const pathPart = removeLeadingDot(rest.join('.home'));
  const directory = transformPathToDirectory(pathPart);

  return `${process.env.HOME}${directory}/${name}${extension}`;
}

// Handle edge case: mise creates ~/.config before symlinks run
function handleConfigEdgeCase() {
  const configPath = path.join(process.env.HOME, '.config');

  if (isSymlink(configPath)) return;

  const contents = fs.readdirSync(configPath).filter(f => !f.startsWith('.'));
  if (contents.length === 1 && contents[0] === 'mise') {
    log.info('~/.config only contains mise/, removing to allow symlink...');
    fs.rmSync(configPath, { recursive: true });
  }
}

// File operations
function isSymlink(filePath) {
  try {
    return fs.lstatSync(filePath).isSymbolicLink();
  } catch {
    return false;
  }
}

function fileExists(filePath) {
  try {
    fs.accessSync(filePath);
    return true;
  } catch {
    return false;
  }
}

function backupFile(filePath) {
  const backupPath = `${filePath}.bak`;
  fs.renameSync(filePath, backupPath);
}

// Core symlinking logic
function handleExistingSymlink(src, dest) {
  const currentLink = fs.readlinkSync(dest);
  if (currentLink === src) {
    log.success(`Link already exists: ${dest} -> ${src}`);
    return true;
  }

  log.warn(`Existing link ${dest} points to ${currentLink}. Backing up...`);
  try {
    backupFile(dest);
    return false; // Continue with link creation
  } catch (error) {
    log.error(`Failed to back up existing link: ${dest}`);
    return true; // Stop processing
  }
}

function handleExistingFile(dest) {
  log.warn(`Existing file ${dest} found. Backing up to ${dest}.bak`);
  try {
    backupFile(dest);
    return true; // Success, continue
  } catch (error) {
    log.error(`Failed to back up existing file: ${dest}`);
    return false; // Failed, stop
  }
}

function createLink(src, dest) {
  try {
    fs.symlinkSync(src, dest);
    log.success(`Created link: ${dest} -> ${src}`);
    return true;
  } catch (error) {
    log.error(`Failed to create link: ${dest} -> ${src}`);
    return false;
  }
}

function safeLink(src, dest) {
  // Handle existing symlink
  if (isSymlink(dest)) {
    const shouldStop = handleExistingSymlink(src, dest);
    if (shouldStop) return true;
  }

  // Handle existing file
  if (fileExists(dest)) {
    if (!handleExistingFile(dest)) return false;
  }

  // Create parent directory and link
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  return createLink(src, dest);
}

function findSymlinkFiles(rootDir) {
  const output = execSync(`find . -name '*.symlink*' \\( -type f -o -type d \\)`, {
    cwd: rootDir,
    encoding: 'utf-8'
  });

  return output
    .trim()
    .split('\n')
    .filter(line => line.length > 0)
    .map(file => path.join(rootDir, file));
}

function linkHomeFiles() {
  log.info(`Finding .home.* files in ${DOTFILES_ROOT}...`);

  const symlinkFiles = findSymlinkFiles(DOTFILES_ROOT);
  let failedCount = 0;

  for (const src of symlinkFiles) {
    const filename = path.basename(src);
    const dest = transformPath(filename);

    if (dest) {
      if (!safeLink(src, dest)) {
        failedCount++;
      }
    } else {
      log.warn(`Could not parse filename pattern: ${filename}`);
    }
  }

  return failedCount;
}

function setupSymlinks() {
  log.info('Starting symlinking process...');

  handleConfigEdgeCase();
  const failedCount = linkHomeFiles();

  if (failedCount > 0) {
    log.error('Symlinking process completed with errors.');
    process.exit(1);
  } else {
    log.success('Symlinking process completed successfully.');
  }
}

// Run if executed directly
if (require.main === module) {
  setupSymlinks();
}

module.exports = { setupSymlinks, safeLink, transformPath };
