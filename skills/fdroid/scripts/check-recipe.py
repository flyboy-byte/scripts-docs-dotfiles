#!/usr/bin/env -S python3 -I
"""Lint an fdroiddata recipe for the mistakes reviewers and the build server actually trip on.

Usage: check-recipe.py <metadata/appid.yml> [--stack rn|gradle|auto]
Read-only. Prints FAIL (will break or be rejected), WARN (reviewers usually ask), INFO.
Exit status 1 if any FAIL. This is not a replacement for CI (`fdroid lint`, rewritemeta,
the scanner); it catches what CI doesn't say clearly, and checks the blocks agree with each other.
Needs PyYAML.
"""
import re, sys
try:
    import yaml
except ImportError:
    sys.exit("needs PyYAML (pip install pyyaml)")

if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
    print(__doc__); sys.exit(0)
path = sys.argv[1]
stack = "auto"
if "--stack" in sys.argv:
    stack = sys.argv[sys.argv.index("--stack") + 1]
raw = open(path).read()
d = yaml.safe_load(raw)
builds = d.get("Builds") or []
res = []
def out(level, msg): res.append((level, msg))

def lines_of(b, key):
    v = b.get(key)
    if v is None: return []
    if isinstance(v, str): return [v]
    if isinstance(v, list): return [str(x) for x in v]
    return [str(v)]
def text(b): return "\n".join(l for k in ("sudo", "init", "prebuild", "build", "postbuild") for l in lines_of(b, k))

# -- top level
for k in ("License", "SourceCode", "IssueTracker", "AuthorName", "Categories", "RepoType", "Repo"):
    if not d.get(k): out("WARN" if k in ("IssueTracker", "AuthorName") else "FAIL", f"missing top-level {k}")
for k in ("Summary", "Description"):
    if d.get(k): out("WARN", f"{k} in the YAML: store text belongs in the app repo's fastlane folder")
aum, ucm = str(d.get("AutoUpdateMode", "None")), str(d.get("UpdateCheckMode", "None"))
if aum == "None" or ucm == "None": out("WARN", f"AutoUpdateMode={aum} UpdateCheckMode={ucm}: reviewers ask for Version/Tags unless there is a reason")
if aum.startswith("Version") and ucm.startswith("Tags") and aum != "Version": out("WARN", f"with Tags, AutoUpdateMode should be plain 'Version' (got '{aum}')")
key = d.get("AllowedAPKSigningKeys")
keys = key if isinstance(key, list) else ([key] if key else [])
for k in keys:
    if not re.fullmatch(r"[0-9a-f]{64}", str(k)): out("FAIL", f"AllowedAPKSigningKeys '{k}' is not 64 lowercase hex")
has_bin = bool(d.get("Binaries")) or any(b.get("binary") for b in builds)
if keys and not has_bin: out("WARN", "AllowedAPKSigningKeys without Binaries/binary: reproducible verification will not run (reviewers will say so)")
if has_bin and not keys: out("FAIL", "Binaries/binary without AllowedAPKSigningKeys")

# -- per build
if not builds: out("FAIL", "no Builds")
versions = []
for i, b in enumerate(builds):
    tag = f"build {b.get('versionName')}/{b.get('versionCode')}"
    c = str(b.get("commit", ""))
    if not re.fullmatch(r"[0-9a-f]{40}", c): out("FAIL", f"{tag}: commit must be a full 40-char hash (got '{c}')")
    if b.get("binary") and not re.search(r"%[vc]", str(b["binary"])): out("WARN", f"{tag}: binary URL has no %v/%c; it must be versioned")
    if b.get("output") and b.get("gradle"): out("WARN", f"{tag}: output: with gradle; reviewers ask to drop it and set subdir instead")
    if b.get("disable"): out("WARN", f"{tag}: disabled build; keep only buildable versions")
    t = text(b)
    if re.search(r"\$VERCODE\$", t) and not re.search(r"\$\$VERCODE\$\$", t): out("FAIL", f"{tag}: $VERCODE$ must be written $$VERCODE$$ in the YAML")
    versions.append((b.get("versionName"), b.get("versionCode")))

# -- number of versions kept
names = []
for n, _ in versions:
    if n not in names: names.append(n)
if len(names) > 3: out("INFO", f"{len(names)} versions in Builds; a new-app MR should keep only the latest (the bot keeps older ones after merge)")

# -- VercodeOperation consistency
ops = d.get("VercodeOperation") or []
if ops:
    groups = {}
    for n, c in versions: groups.setdefault(n, []).append(c)
    for n, cs in groups.items():
        if len(cs) != len(ops): out("FAIL", f"version {n}: {len(cs)} blocks but {len(ops)} VercodeOperation lines")
        else:
            bases = set()
            for op, c in zip(ops, cs):
                m = re.fullmatch(r"\s*(\d+)\s*\*\s*%c\s*\+\s*(\d+)\s*", str(op))
                if m: bases.add((c - int(m.group(2))) / int(m.group(1)))
            if len(bases) > 1: out("FAIL", f"version {n}: codes {cs} do not come from one base code through {ops}")
    if str(d.get("CurrentVersionCode")) != str(versions[-1][1]) if versions else False:
        out("WARN", f"CurrentVersionCode {d.get('CurrentVersionCode')} != last block's versionCode {versions[-1][1]}")

# -- ABI split consistency
for b in builds:
    t = text(b); m = re.search(r'include\s+"([a-z0-9_-]+)"', t)
    if m and b.get("binary") and m.group(1) not in str(b["binary"]):
        out("FAIL", f"build {b['versionCode']}: splits include {m.group(1)} but binary URL is {b['binary']}")

# -- stack: React Native / Expo
alltext = "\n".join(text(b) for b in builds)
is_rn = stack == "rn" or (stack == "auto" and re.search(r"expo|react-native", alltext))
if is_rn:
    needs = [
        (r"expo prebuild -p android --clean", "FAIL", "npx expo prebuild -p android --clean (reviewers: non-negotiable)"),
        (r'buildFromSource', "FAIL", "buildFromSource sed on package.json (template)"),
        (r"jvmToolchain.*17/21|s/17/21", "FAIL", "JDK 17 -> 21 sed on the RN gradle plugin (template)"),
        (r"Inet4Address", "WARN", "LAN-IP sed on AgpConfiguratorUtils.kt (resources.arsc differs per build host otherwise)"),
        (r"foojay", "FAIL", "foojay sed (the offline build server cannot download a JDK; fork CI can, so it hides this)"),
        (r"signingConfig", "WARN", "removal of release signingConfig"),
        (r"VERCODE", "INFO", "$$VERCODE$$ sed (only needed with VercodeOperation)"),
    ]
    for b in builds[-4:]:
        t = text(b)
        for rx, lvl, label in needs:
            if not re.search(rx, t): out(lvl, f"build {b['versionCode']}: no {label}")
        if "node_modules" not in " ".join(lines_of(b, "scandelete")): out("FAIL", f"build {b['versionCode']}: scandelete: node_modules missing (template)")
        if not b.get("ndk"): out("WARN", f"build {b['versionCode']}: ndk not pinned")
        for s in lines_of(b, "scanignore"):
            if "*" in s or s.rstrip("/").endswith("node_modules"): out("FAIL", f"build {b['versionCode']}: scanignore '{s}' is too broad; single files only")
    if re.search(r"abiFilters", alltext): out("FAIL", "abiFilters in the recipe: with AGP 8 + RN it produces universal APKs; use splits.abi")

# -- blocks of the latest version should differ only in versionCode / abi / binary
last = [b for b in builds if b.get("versionName") == (versions[-1][0] if versions else None)]
if len(last) > 1:
    def norm(b):
        t = text(b)
        t = re.sub(r'include "[a-z0-9_-]+"', 'include "ABI"', t)
        t = re.sub(r"\b(armeabi-v7a|arm64-v8a|x86_64|x86)\b", "ABI", t)
        return t
    base = norm(last[0])
    for b in last[1:]:
        if norm(b) != base:
            a, c = base.splitlines(), norm(b).splitlines()
            diff = [l for l in c if l not in a][:3] + [l for l in a if l not in c][:3]
            out("FAIL", f"build {b['versionCode']} differs from {last[0]['versionCode']} beyond the ABI: {diff}")
    for k in ("scanignore", "scandelete", "ndk", "subdir", "gradle", "sudo", "init"):
        if len({repr(b.get(k)) for b in last}) > 1: out("FAIL", f"blocks of {last[0]['versionName']} disagree on {k}")

# -- raw formatting hints
for n, line in enumerate(raw.splitlines(), 1):
    if re.fullmatch(r"\s+binary:", line): out("INFO", f"line {n}: 'binary:' on its own line should end with a trailing space (rewritemeta canonical form)")
    if re.fullmatch(r"\s+- sed -i", line): out("INFO", f"line {n}: '- sed -i' alone on a line should end with a trailing space")
if "\r" in raw: out("FAIL", "CRLF line endings; must be LF")

order = {"FAIL": 0, "WARN": 1, "INFO": 2}
seen = set()
for lvl, msg in sorted(res, key=lambda r: order[r[0]]):
    if (lvl, msg) in seen: continue
    seen.add((lvl, msg)); print(f"{lvl:4}  {msg}")
if not res: print("no findings")
print(f"\n{sum(1 for l,_ in res if l=='FAIL')} fail, {sum(1 for l,_ in res if l=='WARN')} warn, {sum(1 for l,_ in res if l=='INFO')} info  ({len(builds)} builds)")
sys.exit(1 if any(l == "FAIL" for l, _ in res) else 0)
