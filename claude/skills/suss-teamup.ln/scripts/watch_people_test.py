import http.client
import importlib.machinery
import importlib.util
import subprocess
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

WATCH_PEOPLE = Path(__file__).resolve().parent / "watch_people"


def load_watch_people():
    loader = importlib.machinery.SourceFileLoader("watch_people", str(WATCH_PEOPLE))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader("watch_people", loader))
    loader.exec_module(module)
    return module


watch_people = load_watch_people()
GOOD_ITEM = watch_people.Item("slack:C1:1.000000", 2.0, "Chen Levy", "wrote in #channel: hi", "https://slack/p1")


def truncated_slack_read(*_):
    raise http.client.IncompleteRead(b"x" * 49620, 9004)


def source(function, label: str):
    return mock.Mock(side_effect=function, args=(None, label))


def failed_process(*_, **__):
    return subprocess.CompletedProcess([], 1, "", "already a member")


class RaisingSourceDoesNotStopTheWatch(unittest.TestCase):
    def test_items_of_the_healthy_sources_still_arrive(self):
        sources = [source(truncated_slack_read, "C_BROKEN"), source(lambda: [GOOD_ITEM], "C_OK")]
        with mock.patch.object(watch_people, "sources", return_value=sources):
            items = watch_people.new_items(SimpleNamespace(), lambda *_: True)
        self.assertEqual(items, [GOOD_ITEM])

    def test_a_failed_join_is_retried_next_period(self):
        args = SimpleNamespace(channel="inbox", handle="people.watch", throwaway=False, github_users=[], slack_users=[])
        with mock.patch.object(watch_people, "teamup", side_effect=failed_process):
            is_joined = watch_people.run_period(args, seen=None, is_joined=False)
        self.assertFalse(is_joined)

    def test_a_period_that_raises_keeps_the_loop_alive(self):
        with mock.patch.object(watch_people, "post_new_items", side_effect=truncated_slack_read):
            is_joined = watch_people.run_period(SimpleNamespace(), seen=None, is_joined=True)
        self.assertTrue(is_joined)


if __name__ == "__main__":
    unittest.main()
