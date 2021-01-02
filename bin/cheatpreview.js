#!/usr/bin/env node
process.env.FORCE_COLOR = true
const { readFileSync } = require('fs')
const chalk = require('chalk')
const [line, file] = process.argv.splice(2)

const [command, shortcut] = readFileSync(file, 'utf8').split('\n').splice(Number(line) -1, 2)
console.log(chalk.yellow.bgHex('#444444')(command))
console.log(chalk.green(shortcut))
