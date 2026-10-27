"""suss-telegram-user login send | login code | add <chat_id> <bot_username> | fill-pool

Acts as David's own Telegram account (Telethon) for what bots can't do, like adding a bot to a group.
api_id, api_hash and the session live in the login keychain (service suss-telegram). `login send`
reads his phone number on stdin and asks Telegram for a code; `login code` reads the code on stdin.
`fill-pool` creates pool bots through @BotFather until the pool is full or BotFather says wait.
"""
import asyncio
import contextlib
import json
import random
import re
import string
import time
import subprocess
import sys
from pathlib import Path

from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.tl.functions.messages import AddChatUserRequest

KEYCHAIN_SERVICE = "suss-telegram"
PENDING_LOGIN = Path.home() / ".local/state/suss-telegram/pending_login.json"
CONFIG = Path.home() / ".local/share/suss-telegram/config.json"
NEXT_TRY = Path.home() / ".local/state/suss-telegram/botfather_next_try"
POOL_SIZE = 15
POOL_WORDS = ("amber birch cedar dune ember falcon garnet harbor iris juniper kestrel lantern maple nutmeg otter "
              "pebble quartz raven sage tulip").split()
SHORT_WAIT_SECONDS = 120
TOKEN = re.compile(r"\d+:[A-Za-z0-9_-]{30,}")
WAIT = re.compile(r"try again in (\d+) seconds")


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


class BotFatherSaysWait(Exception):
    pass


async def ask_botfather(conversation, text):
    for _ in range(4):
        await conversation.send_message(text)
        reply = (await conversation.get_response()).raw_text
        if not (wait := WAIT.search(reply)):
            return reply
        if int(wait.group(1)) > SHORT_WAIT_SECONDS:
            NEXT_TRY.write_text(str(time.time() + int(wait.group(1))))
            raise BotFatherSaysWait(reply)
        await asyncio.sleep(int(wait.group(1)) + 2)
    return reply


async def create_bot(user, word):
    async with user.conversation("BotFather", timeout=60) as conversation:
        await ask_botfather(conversation, "/newbot")
        await ask_botfather(conversation, word)
        for _ in range(3):
            username = f"susskind_{word}_{''.join(random.choices(string.ascii_lowercase + string.digits, k=4))}_bot"
            reply = await ask_botfather(conversation, username)
            if token := TOKEN.search(reply):
                break
        else:
            await ask_botfather(conversation, "/cancel")
            return print(f"{word}: BotFather refused: {reply[:120]}")
        await ask_botfather(conversation, "/setprivacy")
        await ask_botfather(conversation, f"@{username}")
        await ask_botfather(conversation, "Disable")
    store_secret(word, token.group(0))
    config = json.loads(CONFIG.read_text())
    config["bots"][word] = {"username": username, "pool": True}
    CONFIG.write_text(json.dumps(config, indent=1))
    print(f"{word}: created @{username}, privacy off, in the pool")


def missing_pool_words():
    bots = json.loads(CONFIG.read_text())["bots"]
    missing = POOL_SIZE - sum(1 for entry in bots.values() if entry.get("pool"))
    return [word for word in POOL_WORDS if word not in bots][:max(missing, 0)]


async def fill_pool():
    if NEXT_TRY.exists() and time.time() < float(NEXT_TRY.read_text()):
        return print(f"BotFather said wait; next try after {time.ctime(float(NEXT_TRY.read_text()))}")
    async with connected(secret("user-session")) as user:
        for word in missing_pool_words():
            try:
                await create_bot(user, word)
            except BotFatherSaysWait as wait:
                return print(f"stopped: {wait}")
    print("pool full" if not missing_pool_words() else "pool not full yet")


USAGE = __doc__.strip().split("\n\n")[0]

if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["login", "send"]:
        asyncio.run(send_code())
    elif args == ["login", "code"]:
        asyncio.run(sign_in())
    elif args == ["fill-pool"]:
        asyncio.run(fill_pool())
    elif len(args) == 3 and args[0] == "add":
        asyncio.run(add_to_group(*args[1:]))
    else:
        sys.exit(f"usage: {USAGE}")
