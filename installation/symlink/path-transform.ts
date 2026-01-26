const extractExtension = (filename: string) => filename.replace(/.*symlink/, '')

const removeSymlinkAndExtension = (filename: string) => filename.replace(/\.symlink.*$/, '')

const replaceDOTWithDot = (str: string) => str.replace(/DOT/g, '.')

const removeLeadingDot = (str: string) => str.replace(/^\./, '')

const transformPathToDirectory = (pathPart: string) =>
  pathPart ? '/' + pathPart.replace(/\./g, '/').replace(/DOT/g, '.') : ''

export function transformPath(filename: string) {
  if (!/\.home\./.test(filename)) return null

  const extension = extractExtension(filename)
  const base = removeSymlinkAndExtension(filename)
  const [namePart, ...rest] = base.split('.home')
  const name = replaceDOTWithDot(namePart)
  const pathPart = removeLeadingDot(rest.join('.home'))
  const directory = transformPathToDirectory(pathPart)

  return `${process.env.HOME}${directory}/${name}${extension}`
}
