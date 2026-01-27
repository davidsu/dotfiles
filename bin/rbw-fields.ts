#!/usr/bin/env bun

// Keybinds for fzf actions - consumed as fields are extracted
const KEYS = [
  'ctrl-b', 'ctrl-f', 'ctrl-g', 'ctrl-h', 'ctrl-j', 'ctrl-q', 'ctrl-v', 'ctrl-x',
  'ctrl-r', 'ctrl-t', 'ctrl-y', 'ctrl-l', 'ctrl-d',
  'alt-a', 'alt-b', 'alt-c', 'alt-d', 'alt-e', 'alt-f', 'alt-g', 'alt-h',
  'alt-i', 'alt-j', 'alt-k', 'alt-l', 'alt-m', 'alt-n', 'alt-o', 'alt-p',
  'alt-q', 'alt-r', 'alt-s', 'alt-t', 'alt-u', 'alt-v', 'alt-w', 'alt-x',
  'alt-y', 'alt-z',
]

interface Keybind {
  rawKey: string
  displayKey: string
}

export interface FieldEntry {
  label: string
  displayValue: string
  rawValue: string | null
  rawKey: string
  displayKey: string
}

interface RbwData {
  username?: string
  password?: string
  totp?: string
  uris?: Array<{ uri: string }>
  [key: string]: string | Array<{ uri: string }> | undefined
}

interface RbwField {
  name: string
  type?: string
  value: string
}

interface RbwJson {
  data?: RbwData
  fields?: RbwField[]
  notes?: string
}

const nextKeybind = (): Keybind => {
  const rawKey = KEYS.shift()
  if (!rawKey) return { rawKey: '', displayKey: '' }

  const displayKey = rawKey.replace('ctrl-', 'Ctrl+').replace('alt-', 'Alt+')
  return { rawKey, displayKey }
}

export const humanizeKey = (key: string) =>
  key
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ') + ':'

const SENSITIVE_KEYS = [
  'password',
  'number',
  'code',
  'totp',
  'cvv',
  'ssn',
  'passport_number',
]

export const shouldMask = (key: string) =>
  SENSITIVE_KEYS.includes(key.toLowerCase())

export const getMaskForKey = (key: string) => {
  if (key === 'number') return '\u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022 \u2022\u2022\u2022\u2022'
  if (key === 'code' || key === 'cvv') return '\u2022\u2022\u2022'
  return '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022'
}

const extractData = (json: RbwJson): FieldEntry[] =>
  Object.entries(json.data || {})
    .filter(([key, value]) => key !== 'uris' && value && typeof value === 'string')
    .map(([key, value]) => {
      const { rawKey, displayKey } = nextKeybind()
      return {
        label: humanizeKey(key),
        displayValue: shouldMask(key) ? getMaskForKey(key) : (value as string),
        rawValue: value as string,
        rawKey,
        displayKey,
      }
    })

const extractUris = (json: RbwJson): FieldEntry[] => {
  const uris = json.data?.uris as Array<{ uri: string }> | undefined
  const firstUri = uris?.[0]?.uri
  if (!firstUri) return []

  const { rawKey, displayKey } = nextKeybind()
  return [
    {
      label: 'Website:',
      displayValue: firstUri,
      rawValue: firstUri,
      rawKey,
      displayKey,
    },
  ]
}

const extractFields = (json: RbwJson): FieldEntry[] =>
  (json.fields || []).map((field) => {
    const { rawKey, displayKey } = nextKeybind()
    return {
      label: field.name + ':',
      displayValue: field.type === 'hidden' ? '\u2022\u2022\u2022\u2022\u2022\u2022\u2022' : field.value,
      rawValue: field.value,
      rawKey,
      displayKey,
    }
  })

const extractNotes = (json: RbwJson): FieldEntry[] =>
  json.notes
    ? [
        {
          label: 'Notes:',
          displayValue: json.notes,
          rawValue: json.notes,
          rawKey: '',
          displayKey: '',
        },
      ]
    : []

const SPACER: FieldEntry = {
  label: ' ',
  displayValue: ' ',
  rawValue: null,
  rawKey: '',
  displayKey: '',
}

export const extractEntries = (json: RbwJson): FieldEntry[] => [
  ...extractData(json),
  ...extractUris(json),
  SPACER,
  ...extractFields(json),
  SPACER,
  ...extractNotes(json),
]

export const generateFzfBindings = () =>
  KEYS.map(
    (key) =>
      `${key}:execute-silent($HOME/.dotfiles/bin/rbw-copy-field-by-keybind.ts {} ${key})`
  ).join(',')

if (import.meta.main) {
  console.log(generateFzfBindings())
}
