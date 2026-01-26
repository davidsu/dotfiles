#!/usr/bin/env bun

import { mkdirSync, appendFileSync } from 'fs'
import { homedir } from 'os'
import path from 'path'

const LOG_DIR = path.join(homedir(), 'Library', 'Logs', 'dotfiles')
const INSTALL_LOG = path.join(LOG_DIR, 'install.log')
const ERROR_LOG = path.join(LOG_DIR, 'install_errors.log')

mkdirSync(LOG_DIR, { recursive: true })

export const RED = '\x1b[0;31m'
export const GREEN = '\x1b[0;32m'
export const YELLOW = '\x1b[0;33m'
export const BLUE = '\x1b[0;34m'
export const RESET = '\x1b[0m'

export function colorize(color: string, text: string) {
  return `${color}${text}${RESET}`
}

function formatTimestamp() {
  return new Date().toISOString().replace('T', ' ').substring(0, 19)
}

function formatMessage(level: string, message: string) {
  return `[${formatTimestamp()}] [${level}] ${message}`
}

function writeToLog(logPath: string, message: string) {
  appendFileSync(logPath, message + '\n')
}

function info(message: string) {
  const formatted = formatMessage('INFO', message)
  writeToLog(INSTALL_LOG, formatted)
  console.log(colorize(BLUE, formatted))
}

function success(message: string) {
  const formatted = formatMessage('SUCCESS', message)
  writeToLog(INSTALL_LOG, formatted)
  console.log(colorize(GREEN, formatted))
}

function warn(message: string) {
  const formatted = formatMessage('WARN', message)
  writeToLog(INSTALL_LOG, formatted)
  console.log(colorize(YELLOW, formatted))
}

function error(message: string) {
  const formatted = formatMessage('ERROR', message)
  writeToLog(INSTALL_LOG, formatted)
  writeToLog(ERROR_LOG, formatted)
  console.error(colorize(RED, formatted))
}

function banner(message: string) {
  const border = '='.repeat(60)
  const lines = ['', border, `  ${message}`, border, '']

  for (const line of lines) {
    console.log(colorize(YELLOW, line))
  }

  writeToLog(INSTALL_LOG, lines.join('\n'))
}

export const log = { info, success, warn, error, banner }
