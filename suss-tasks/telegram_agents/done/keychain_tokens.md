closed
# 📨 Bot tokens in the keychain

## Summary

Bot tokens move from `~/.local/share/suss-teamup/telegram.json` to the login keychain (service
`suss-telegram`, account = bot name); the file keeps chat ids and names. Done: `security find-generic-password` reads them, cached per
process; writes pipe `security -i` on stdin, so a token never sits on a command line. David, line 2493 of the
session in [design.md](design.md): "I hate secrets on files".

---
**Created by**: teamup.telegram (2026-10-27)
**b44sync**: never
