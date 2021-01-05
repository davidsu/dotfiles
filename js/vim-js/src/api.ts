import { workspace } from 'coc.nvim'
let resolve
const apiPromise = new Promise(r => (resolve = r))
export const getApi = (): any => apiPromise
workspace.nvim.requestApi().then(api => {
  const deserialized = api[1].functions.reduce((map, { name }) => {
    map[name] = (...args) => workspace.nvim.request(name, args)
    return map
  }, {})
  deserialized.___api = api[1].functions.reduce((map, _api) => {
    map[_api.name] = _api
    return map
  }, {})

  resolve(deserialized)
})
