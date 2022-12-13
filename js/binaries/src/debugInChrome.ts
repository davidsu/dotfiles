/* eslint-disable no-console */
import fetch from 'node-fetch'
import { exec } from 'child_process'
//@ts-ignore
import dns from 'node:dns'
dns.setDefaultResultOrder('ipv4first')

function openChromeDevTools(url) {
  // for some reason the appleScript `open location` command does't work with this url, worked around using sequence of keystrokes
  // doesn't work from terminal `open -a 'Goole Chrome' ${url}` either
  console.log({ url })
  const osascript = `
            osascript << 'END'
            tell application "Google Chrome"
                activate

                #force open devtools, shouldn't have to do that, buggy computer at work
                tell application "System Events" to keystroke "i" using { command down, option down }

                tell application "System Events" to keystroke "l" using command down
                delay 0.05
                tell application "System Events" to keystroke "${url}"
                tell application "System Events" to keystroke key code 36

                #close the devtools that I opened by force
                tell application "System Events" to keystroke "i" using { command down, option down }
            end tell
            END
             `
  // console.log(osascript)
  exec(osascript)
}

export const openChromeOnDebuggerUrl = (port = 9229, retry = 0) =>
  fetch(`http://localhost:${port}/json/list`) //curl http://localhost:9229/json/list
    .then(response => response.json())
    //@ts-expect-error
    .then(r => console.log('chrome url for debugging -> ', r) || r)
    .then(([{ devtoolsFrontendUrl, devtoolsFrontendUrlCompat }]) =>
      openChromeDevTools(devtoolsFrontendUrl || devtoolsFrontendUrlCompat)
    )
    .catch(() => {
      if (retry < 50) {
        setTimeout(() => openChromeOnDebuggerUrl(port, retry + 1), 20)
      } else {
        console.log('unable to get url to open devtools')
      }
    })
