"""suss-telegram-user login send | login code | add <chat_id> <bot_username>

Acts as David's own Telegram account (Telethon) for what bots can't do, like adding a bot to a group.
api_id, api_hash and the session live in the login keychain (service suss-telegram). `login send`
reads his phone number on stdin and asks Telegram for a code; `login code` reads the code on stdin.
"""
import asyncio
import contextlib
import json
import subprocess
import sys
from pathlib import Path

from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.tl.functions.messages import AddChatUserRequest

KEYCHAIN_SERVICE = "suss-telegram"
PENDING_LOGIN = Path.home() / ".local/state/suss-telegram/pending_login.json"


def secret(account):
    found = subprocess.run(["security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-a", account, "-w"],
                           capture_output=True, text=True)
    return found.stdout.strip() if found.returncode == 0 else None


def store_secret(account, value):
    command = f"add-generic-password -U -s {KEYCHAIN_SERVICE} -a {account} -w {value}\n"
    subprocess.run(["security", "-i"], input=command, capture_output=True, text=True, check=True)


@contextlib.asynccontextmanager
async def connected(session=""):
    user = TelegramClient(StringSession(session), int(secret("user-api-id")), secret("user-api-hash"))
    await user.connect()
    try:
        yield user
    finally:
        await user.disconnect()


async def send_code():
    phone = sys.stdin.readline().strip()
    async with connected() as user:
        sent = await user.send_code_request(phone)
        PENDING_LOGIN.parent.mkdir(parents=True, exist_ok=True)
        PENDING_LOGIN.write_text(json.dumps({"phone": phone, "hash": sent.phone_code_hash,
                                             "session": user.session.save()}))
        PENDING_LOGIN.chmod(0o600)
    print("code sent to David's Telegram")


async def sign_in():
    pending = json.loads(PENDING_LOGIN.read_text())
    async with connected(pending["session"]) as user:
        await user.sign_in(pending["phone"], sys.stdin.readline().strip(), phone_code_hash=pending["hash"])
        store_secret("user-session", user.session.save())
    PENDING_LOGIN.unlink()
    print("signed in; session stored in the keychain")


async def add_to_group(chat_id, username):
    async with connected(secret("user-session")) as user:
        await user(AddChatUserRequest(chat_id=abs(int(chat_id)), user_id=username, fwd_limit=0))
    print(f"added @{username} to chat {chat_id}")


USAGE = __doc__.strip().split("\n\n")[0]

if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["login", "send"]:
        asyncio.run(send_code())
    elif args == ["login", "code"]:
        asyncio.run(sign_in())
    elif len(args) == 3 and args[0] == "add":
        asyncio.run(add_to_group(*args[1:]))
    else:
        sys.exit(f"usage: {USAGE}")
