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
        console.log('wait')
        delay(0.2)
    }
}

function closeTabIfOnPr(pr, w) {
    if(new RegExp(pr).test(w.activeTab.url())) {
        w.activeTab.close()
    }
}

function navigateToLatestBuild(w, url) {
    while(w.activeTab.url() === url) {
        console.log('delay')
        delay(0.2)
        w.activeTab.execute({javascript: 'document.querySelector(".JTable-row.JTable-row--rollOver").firstElementChild.click()'})
    }
}

function run(pr) {
    if(/^\d/.test(pr)) {
        pr = `PR-${pr}`
    }
    if(!/PR-\d{4}/.test(pr)) {
        console.error('usage: insist.js PR-NNNN')
        return
    }
    const url =  `https://jenkins.walkmedev.com/blue/organizations/jenkins/sanity%2Fplayer/activity/?branch=${pr}`
    const w = Application("Google Chrome").windows[0]

    closeTabIfOnPr(pr, w)
    w.tabs.push(Application("Google Chrome").Tab({url}))
    pollLoading(w)

    navigateToLatestBuild(w, url)
    delay(0.5)
    w.activeTab.execute({javascript: `(${rerunIfFailed.toString()})()`})
    delay(60 * 7)
    run(pr)
}
