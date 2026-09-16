#!/usr/bin/env bun

const blue = (text: string) => `\x1b[38;5;12m${text}\x1b[0m`
const green = (text: string) => `\x1b[38;5;10m${text}\x1b[0m`
const gray = (text: string) => `\x1b[38;5;8m${text}\x1b[0m`

const decodeLoosely = (text: string) => {
  try {
    return decodeURIComponent(text)
  } catch {
    return text
  }
}

const renderParams = (params: URLSearchParams) => {
  const names = [...params.keys()]
  const width = Math.max(...names.map((name) => name.length))
  return [...params.entries()].map(
    ([name, value]) => `${green(name.padEnd(width))} ${gray('=')} ${decodeLoosely(value)}`,
  )
}

const renderUrl = (url: URL) => [
  blue(url.origin === 'null' ? `${url.protocol}//${url.host}` : url.origin),
  decodeLoosely(url.pathname),
  ...renderParams(url.searchParams),
  ...(url.hash ? [gray(url.hash)] : []),
]

const render = (raw: string) => {
  try {
    return renderUrl(new URL(raw))
  } catch {
    return [blue(raw)]
  }
}

console.log(render(process.argv[2] ?? '').join('\n'))
