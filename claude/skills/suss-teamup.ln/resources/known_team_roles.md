# Known team roles and their colors

An agent's color tells the user its role at a glance, on any team. The color goes on both the
iTerm tab and claude's `/color`.

| Role     | Who                                            | Color                                 |
|----------|------------------------------------------------|---------------------------------------|
| `lead`   | runs the job and briefs the other agents       | blue                                  |
| `owner`  | owns one unit of work, such as a PR             | yellow                                |
| `keeper` | keeps a shared record, such as a tracking file | red                                   |
| anyone else | testers, reviewers, helpers, plain peers    | a random one of orange, pink, cyan    |

Blue, yellow, green, purple and red are never given to "anyone else".

## Applying it

- **Spawn**: `teamup-spawn … --role lead|owner|keeper|<other>`. With neither `--role` nor
  `--color`, the new agent takes **the spawner's own color**: a handoff successor carries on
  as what its predecessor was. A spawner with no color gives "anyone else"'s.
  So a lead spawning a tester or helper passes `--role tester` (any unreserved role), or the
  helper comes up blue like the lead.
- **Wake**: `teamup-wake <handle> --role …` gives the role's color. No `--role` keeps the
  color the session had before it slept, so sleep and wake never change it.
- `--color` on either overrides the role.
- **An agent never recolors its own tab**: the user may have chosen that color.

The mapping lives in one place, `scripts/session_colors.sh` (`role_color`); both scripts read it.
