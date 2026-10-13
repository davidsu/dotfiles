"""David's Slack web session (keychain xoxc token + xoxd cookie) and user lookup."""
import functools
import getpass
import json
import subprocess
import sys
import urllib.parse
import urllib.request


@functools.cache
def slack_users() -> list[dict]:
    users, cursor = [], ""
    while True:
        page = slack_api("users.list", limit="200", **({"cursor": cursor} if cursor else {}))
        users += [user for user in page["members"] if not user.get("deleted")]
        cursor = page.get("response_metadata", {}).get("next_cursor")
        if not cursor:
            return users


def names_of(user: dict) -> set[str]:
    profile = user.get("profile", {})
    return {name.lower() for name in (user.get("real_name"), profile.get("real_name"), profile.get("display_name")) if name}


def user_id_for(name: str) -> str:
    matches = [user for user in slack_users() if name.lower() in names_of(user)]
    if len(matches) != 1:
        found = ", ".join(f"{user.get('real_name')} ({user['id']})" for user in matches) or "nobody"
        sys.exit(f"slack-post: @[{name}] must match exactly one Slack user by full or display name; found {found}")
    return matches[0]["id"]


@functools.cache
def keychain_secret(name: str) -> str:
    return subprocess.run(["security", "find-generic-password", "-a", getpass.getuser(), "-s", name, "-w"],
                          capture_output=True, text=True, check=True).stdout.strip()


def slack_api(method: str, **fields) -> dict:
    body = urllib.parse.urlencode({"token": keychain_secret("slack-mcp-xoxc"), **fields}).encode()
    request = urllib.request.Request(f"https://slack.com/api/{method}", data=body,
                                     headers={"Cookie": f"d={keychain_secret('slack-mcp-xoxd')}"})
    with urllib.request.urlopen(request, timeout=30) as response:
        result = json.load(response)
    if not result.get("ok"):
        sys.exit(f"slack-post: {method} failed: {result.get('error')}")
    return result
