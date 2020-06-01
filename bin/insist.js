#!/usr/bin/osascript

function rerunIfFailed(count = 0) {
    if(count > 10) {
        console.log('not failed')
        return
    }
    console.log('...', count)
    if(!document.querySelector('.BasicHeader')) {
        return setTimeout(rerunIfFailed, 100)
    }
    if(document.querySelector('.BasicHeader--failure')) {
        document.querySelector('a.replay-button ').click()
    } else {
        return setTimeout(() => rerunIfFailed(count + 1), 300)
    }
}

function pollLoading(w) {
    while(w.activeTab.loading()) {
        console.log('poll loading wait')
        delay(0.2)
    }
}

function closeTabIfOnPr(prs, w) {
    for(const pr of prs) {
        if(new RegExp(pr).test(w.activeTab.url())) {
            w.activeTab.close()
        }
    }
}

function navigateToLatestBuild(w, url) {
    while(w.activeTab.url() === url) {
        console.log(`wait window url to ${url}`)
        delay(0.2)
        w.activeTab.execute({javascript: 'document.querySelector(".JTable-row.JTable-row--rollOver").firstElementChild.click()'})
    }
}

const getPrsFromArgs = args => {
    if(!Array.isArray(args)) {
        args = [args]
    }
    return args.filter(pr => /^(PR-)?\d{4}/.test(pr)).map(p => String(p).replace(/^(\d)/, 'PR-$1'))
}
function run(args) {
    prs = getPrsFromArgs(args)
    console.log('START => insist for prs: ', JSON.stringify(prs))
    for(const pr of prs) {
        if(!/PR-\d{4}/.test(pr)) {
            console.error('usage: insist.js PR-NNNN')
            return
        }
        const url = `https://jenkins-ecs.walkmernd.com/blue/organizations/jenkins/sanity%2Fplayer/activity/?branch=${pr}`
        const w = Application("Google Chrome").windows[0]

        closeTabIfOnPr(prs, w)
        w.tabs.push(Application("Google Chrome").Tab({url}))
        pollLoading(w)

        navigateToLatestBuild(w, url)
        delay(0.5)
        w.activeTab.execute({javascript: `(${rerunIfFailed.toString()})()`})
        delay(3)
    }
    console.log('finish run, delay till next run')
    delay(60 * 7)
    run(args)
}
