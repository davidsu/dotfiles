"""David's Slack web session (keychain xoxc token + xoxd cookie) and user lookup."""
import functools
import getpass
import json
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HTTP_TOO_MANY_REQUESTS = 429
HTTP_SERVER_ERROR = 500
RATE_LIMIT_RETRIES = 3
MAX_RETRY_AFTER_SECONDS = 30


class SlackError(Exception):
    def __init__(self, message: str, is_outcome_unknown: bool = False):
        super().__init__(message)
        self.is_outcome_unknown = is_outcome_unknown


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


def post_form(method: str, fields: dict) -> dict:
    body = urllib.parse.urlencode({"token": keychain_secret("slack-mcp-xoxc"), **fields}).encode()
    request = urllib.request.Request(f"https://slack.com/api/{method}", data=body,
                                     headers={"Cookie": f"d={keychain_secret('slack-mcp-xoxd')}"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def post_form_retrying_rate_limits(method: str, fields: dict, retries_left: int = RATE_LIMIT_RETRIES) -> dict:
    try:
        return post_form(method, fields)
    except urllib.error.HTTPError as err:
        retry_after_header = err.headers.get("Retry-After")
        retry_after = int(retry_after_header or 1)
        is_retryable = err.code == HTTP_TOO_MANY_REQUESTS and retries_left and retry_after <= MAX_RETRY_AFTER_SECONDS
        if not is_retryable:
            retry_note = f", Retry-After {retry_after_header}s" if retry_after_header else ""
            raise SlackError(f"{method} failed: HTTP {err.code} {err.reason}{retry_note}",
                             is_outcome_unknown=err.code >= HTTP_SERVER_ERROR) from err
        print(f"slack-post: {method} rate-limited, retrying in {retry_after}s", file=sys.stderr)
        time.sleep(retry_after)
        return post_form_retrying_rate_limits(method, fields, retries_left - 1)


def slack_api(method: str, **fields) -> dict:
    result = post_form_retrying_rate_limits(method, fields)
    if not result.get("ok"):
        raise SlackError(f"{method} failed: {result.get('error')}")
    return result
