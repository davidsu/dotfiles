import fs from 'fs'
import path from 'path'
import { isSymlink, fileExists } from './file-ops'
import { handleExistingSymlink, handleExistingFile, createLink } from './handlers'

export interface LinkResult {
  from: string
  to: string
  success: boolean
  alreadyExists: boolean
}

class SymlinkOperation {
  private src: string
  private dest: string | null
  private linkResult: LinkResult | null = null

  constructor(src: string, dest: string | null) {
    this.src = src
    this.dest = dest
  }

  handleNullDestination() {
    if (this.linkResult) return this

    if (!this.dest) {
      this.linkResult = { from: this.src, to: '<unparseable>', success: false, alreadyExists: false }
    }
    return this
  }

  handleSymlink() {
    if (this.linkResult || !this.dest) return this

    if (isSymlink(this.dest)) {
      const shouldStop = handleExistingSymlink(this.src, this.dest)
      if (shouldStop) {
        this.linkResult = { from: this.src, to: this.dest, success: true, alreadyExists: true }
      }
    }
    return this
  }

  handleExistingFile() {
    if (this.linkResult || !this.dest) return this

    if (fileExists(this.dest)) {
      if (!handleExistingFile(this.dest)) {
        this.linkResult = { from: this.src, to: this.dest, success: false, alreadyExists: false }
      }
    }
    return this
  }

  createSymlink() {
    if (this.linkResult || !this.dest) return this

    fs.mkdirSync(path.dirname(this.dest), { recursive: true })
    const success = createLink(this.src, this.dest)
    this.linkResult = { from: this.src, to: this.dest, success, alreadyExists: false }
    return this
  }

  result() {
    return this.linkResult!
  }
}

export const safeLink = (src: string, dest: string | null) =>
  new SymlinkOperation(src, dest)
    .handleNullDestination()
    .handleSymlink()
    .handleExistingFile()
    .createSymlink()
    .result()
