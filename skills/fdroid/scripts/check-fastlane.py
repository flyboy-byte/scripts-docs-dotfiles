#!/usr/bin/env -S python3 -I
"""Check an app repo's fastlane store text against F-Droid's rules.

Usage: check-fastlane.py <repo-dir> [versionCode ...]
  Give the final F-Droid version codes (e.g. 181 182 183 184) to check each has a changelog.
Read-only. Limits are from https://f-droid.org/docs/All_About_Descriptions_Graphics_and_Screenshots/
"""
import os, re, struct, sys
if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
    print(__doc__); sys.exit(0)
repo = sys.argv[1]; codes = sys.argv[2:]
res = []
def out(l, m): res.append((l, m))
base = None
for p in ("fastlane/metadata/android", "metadata"):
    if os.path.isdir(os.path.join(repo, p, "en-US")): base = os.path.join(repo, p, "en-US"); break
if not base:
    print("FAIL  no en-US folder under fastlane/metadata/android/ or metadata/"); sys.exit(1)
def read(n):
    f = os.path.join(base, n)
    return open(f, encoding="utf-8").read() if os.path.isfile(f) else None
lim = {"short_description.txt": (80, True), "full_description.txt": (4000, True), "title.txt": (50, False)}
for n, (mx, req) in lim.items():
    t = read(n)
    if t is None: out("FAIL" if req else "INFO", f"{n} missing" + (" (mandatory)" if req else "")); continue
    t = t.rstrip("\n")
    if len(t) > mx: out("FAIL", f"{n} is {len(t)} chars, max {mx}")
    elif req and not t.strip(): out("FAIL", f"{n} is empty")
    else: out("OK", f"{n}: {len(t)}/{mx}")
fd = read("full_description.txt") or ""
if re.search(r"^#{1,6} |\*\*[^*]+\*\*|^\s*[-*] ", fd, re.M): out("WARN", "full_description.txt looks like Markdown; F-Droid renders a small HTML subset (b, i, em, strong, br, ul, ol, li, ...). Use <ul><li> and <b>")
bad = set(re.findall(r"</?(applet|base|body|button|embed|form|head|html|iframe|img|input|link|object|picture|script|source|style|svg|video)\b", fd, re.I))
if bad: out("FAIL", f"prohibited HTML tags in full_description.txt: {sorted(bad)}")
cl = os.path.join(base, "changelogs")
have = sorted(os.listdir(cl)) if os.path.isdir(cl) else []
for c in codes:
    f = f"{c}.txt"
    if f not in have: out("FAIL", f"changelogs/{f} missing (F-Droid looks up the FINAL version code, not the base code)")
    else:
        n = len(open(os.path.join(cl, f), encoding="utf-8").read().rstrip("\n"))
        out("FAIL" if n > 500 else "OK", f"changelogs/{f}: {n}/500")
if not codes and have: out("INFO", f"changelogs present: {', '.join(have[-6:])} (pass version codes to check specific ones)")
img = os.path.join(base, "images")
def png_size(f):
    with open(f, "rb") as h:
        b = h.read(24)
    return struct.unpack(">II", b[16:24]) if b[:8] == b"\x89PNG\r\n\x1a\n" else None
for n, need in (("icon.png", True), ("featureGraphic.png", False)):
    f = os.path.join(img, n)
    if os.path.isfile(f):
        s = png_size(f); out("OK", f"images/{n} {s[0]}x{s[1]}" if s else f"images/{n} (not a PNG?)")
    else: out("WARN" if need else "INFO", f"images/{n} missing")
shots = [x for x in os.listdir(os.path.join(img, "phoneScreenshots"))] if os.path.isdir(os.path.join(img, "phoneScreenshots")) else []
out("OK" if len(shots) >= 2 else "WARN", f"phoneScreenshots: {len(shots)} (reviewers expect real screenshots; 4-8 is typical)")
locales = [d for d in os.listdir(os.path.dirname(base)) if os.path.isdir(os.path.join(os.path.dirname(base), d))]
out("INFO", f"locales: {', '.join(sorted(locales))}")
for l, m in sorted(res, key=lambda r: ["FAIL", "WARN", "INFO", "OK"].index(r[0])): print(f"{l:4}  {m}")
sys.exit(1 if any(l == "FAIL" for l, _ in res) else 0)
