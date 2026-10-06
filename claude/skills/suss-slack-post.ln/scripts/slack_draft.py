"""A slack-post draft: parsing, linting, and rendering it as Slack rich_text, mrkdwn or a preview."""
import re
import sys
from dataclasses import dataclass
from pathlib import Path

from slack_session import user_id_for

MAX_LINES = 6
MAX_WORDS_PER_LINE = 20
INLINE = re.compile(r"@\[(?P<mention>[^\]]+)\]|\[(?P<label>[^\]]+)\]\((?P<url>[^)\s]+)\)|`(?P<code>[^`]+)`|(?P<bare>https?://\S+)|_(?P<italic>[^_]+)_")
LOCAL_PATH = re.compile(r"(^|\s)(~/|/Users/|/tmp/|/private/)")
MENTION = re.compile(r"@\[([^\]]+)\]")
SIGNATURE = re.compile(r"^_agent: [\w.-]+_$")


@dataclass
class Draft:
    lines: list[str]

    @property
    def link_count(self) -> int:
        return sum(1 for line in self.lines for match in INLINE.finditer(line) if match["url"] or match["bare"])

    @property
    def mentions(self) -> list[str]:
        return [match["mention"] for line in self.lines for match in INLINE.finditer(line) if match["mention"]]


def read_draft(path: str) -> Draft:
    text = sys.stdin.read() if path == "-" else Path(path).read_text()
    return Draft([line.rstrip() for line in text.strip().splitlines()])


def is_bullet(line: str) -> bool:
    return line.startswith("- ")


def without_bullet(line: str) -> str:
    return line[2:] if is_bullet(line) else line


def inline_elements(line: str) -> list[dict]:
    elements, cursor = [], 0
    for match in INLINE.finditer(line):
        if match.start() > cursor:
            elements.append({"type": "text", "text": line[cursor:match.start()]})
        elements.append(element_for(match))
        cursor = match.end()
    if cursor < len(line):
        elements.append({"type": "text", "text": line[cursor:]})
    return elements


def element_for(match: re.Match) -> dict:
    if match["mention"]:
        return {"type": "user", "user_id": user_id_for(match["mention"])}
    if match["url"]:
        return {"type": "link", "url": match["url"], "text": match["label"]}
    if match["bare"]:
        return {"type": "link", "url": match["bare"]}
    if match["code"]:
        return {"type": "text", "text": match["code"], "style": {"code": True}}
    return {"type": "text", "text": match["italic"], "style": {"italic": True}}


def section(line: str, newline: bool) -> dict:
    tail = [{"type": "text", "text": "\n"}] if newline else []
    return {"type": "rich_text_section", "elements": inline_elements(line) + tail}


def rich_text_blocks(draft: Draft) -> list[dict]:
    elements = []
    for index, line in enumerate(draft.lines):
        is_last = index == len(draft.lines) - 1
        if is_bullet(line):
            add_bullet(elements, section(without_bullet(line), newline=False))
        else:
            elements.append(section(line, newline=not is_last))
    return [{"type": "rich_text", "elements": elements}]


def add_bullet(elements: list[dict], item: dict):
    if elements and elements[-1]["type"] == "rich_text_list":
        elements[-1]["elements"].append(item)
    else:
        elements.append({"type": "rich_text_list", "style": "bullet", "elements": [item]})


def as_mrkdwn(line: str) -> str:
    line = MENTION.sub(lambda match: f"<@{user_id_for(match[1])}>", line)
    line = re.sub(r"\[([^\]]+)\]\(([^)\s]+)\)", r"<\2|\1>", line)
    return f"• {without_bullet(line)}" if is_bullet(line) else line


def as_plain(line: str) -> str:
    return re.sub(r"\[([^\]]+)\]\([^)\s]+\)", r"\1", MENTION.sub(r"@\1", without_bullet(line)))


def lint(draft: Draft, is_signed: bool) -> list[str]:
    problems = [problem for number, line in enumerate(draft.lines, 1) for problem in line_problems(number, line)]
    for name in draft.mentions:
        user_id_for(name)
    if is_signed and (not draft.lines or not SIGNATURE.match(draft.lines[-1])):
        problems.append("last line must be the signature: _agent: <handle>_")
    return problems


def length_notes(draft: Draft) -> list[str]:
    notes = [f"{len(draft.lines)} lines: can it be shorter?"] if len(draft.lines) > MAX_LINES else []
    for number, line in enumerate(draft.lines, 1):
        words = len(as_plain(re.sub(r"https?://\S+", "LINK", line)).split())
        if words > MAX_WORDS_PER_LINE:
            notes.append(f"line {number}: {words} words: can it be shorter?")
    return notes


def line_problems(number: int, line: str) -> list[str]:
    problems = [f"line {number}: code fence — Slack shows it raw"] if "```" in line else []
    if LOCAL_PATH.search(line):
        problems.append(f"line {number}: local path — nobody in Slack can open it")
    if has_bare_url_in_sentence(line):
        problems.append(f"line {number}: bare URL inside a sentence — use [label](url)")
    return problems


def has_bare_url_in_sentence(line: str) -> bool:
    has_bare_url = any(match["bare"] for match in INLINE.finditer(line))
    return has_bare_url and not re.fullmatch(r"(- )?https?://\S+", line.strip())


def preview(draft: Draft) -> str:
    return "\n".join(f"> {'• ' if is_bullet(line) else ''}{MENTION.sub(r'**@\1**', without_bullet(line))}"
                     for line in draft.lines)
