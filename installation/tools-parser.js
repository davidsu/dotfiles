#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Load and parse tools.json file with error handling
 */
function loadTools(toolsPath) {
  try {
    if (!fs.existsSync(toolsPath)) {
      throw new Error(`File not found: ${toolsPath}`);
    }

    const data = fs.readFileSync(toolsPath, 'utf8');
    const parsed = JSON.parse(data);

    if (!parsed.tools || typeof parsed.tools !== 'object') {
      throw new Error('Invalid tools.json format: missing or invalid "tools" object');
    }

    return parsed.tools;
  } catch (error) {
    console.error(`Error reading tools.json: ${error.message}`);
    process.exit(1);
  }
}

/**
 * Generate package list for installation (format: package_name:brew_type)
 */
function generatePackageList(tools) {
  return Object.keys(tools).map(name => {
    const tool = tools[name];
    const packageName = tool.homebrew_package || name;
    const brewType = tool.brew_type || 'formula';
    return `${packageName}:${brewType}`;
  });
}

/**
 * Generate verification list for post-install checks (format: tool_name:brew_type:cmd_name)
 */
function generateVerificationList(tools) {
  return Object.keys(tools).map(name => {
    const tool = tools[name];
    const brewType = tool.brew_type || 'formula';
    const cmd = tool.cmd || name;
    return `${name}:${brewType}:${cmd}`;
  });
}

// Main execution
if (require.main === module) {
  const [,, toolsPath, mode] = process.argv;

  if (!toolsPath || !mode) {
    console.error('Usage: node tools-parser.js <tools.json> <mode>');
    console.error('Modes: packages, verification');
    process.exit(1);
  }

  const tools = loadTools(toolsPath);

  if (mode === 'packages') {
    const packages = generatePackageList(tools);
    console.log(packages.join('\n'));
  } else if (mode === 'verification') {
    const verificationList = generateVerificationList(tools);
    console.log(verificationList.join('\n'));
  } else {
    console.error(`Unknown mode: ${mode}`);
    console.error('Valid modes: packages, verification');
    process.exit(1);
  }
}

module.exports = { loadTools, generatePackageList, generateVerificationList };
