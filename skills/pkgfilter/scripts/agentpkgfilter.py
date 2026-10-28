#!/usr/bin/env python3
"""
agentpkgfilter.py — the agent-friendly pkgfilter (Arch Linux bloat hunter)

The original pkgfilter.py is interactive; this one adds modes that never prompt, so a person
or an AI agent can drive it one command at a time:

  --scan [PATH]            largest directories and files under PATH (default: your home)
  --scan PATH --children   the immediate children of PATH by size (drill down one level)
  --top-packages           largest installed packages (read-only, saves nothing)
  --state-dir DIR          where the revisionN.txt package lists are kept
  --reset                  forget the revisions and start from pacman again
  --orphans                packages nothing needs any more, with sizes (read-only)
  --orphans-detail         the same with install date, repo/AUR, class, description and what removal would also take
  --cache-report           what the pacman and yay caches hold and what paccache could reclaim (read-only)
  -k WORD / -s SIZE        as in pkgfilter.py: strip a keyword / drop packages under a size

What to keep (a personal file, ~/.config/pkgfilter/prefs.json, not part of this repo):
  --keep PATH [--reason R]       never touch PATH; every table marks it KEEP
  --caution PATH [--reason R]    only obvious bloat inside PATH (build output, caches); marked CAUTION
  --keep-pkg GLOB / --caution-pkg GLOB   the same for package names, e.g. 'arm-none-eabi-*'
  --forget PATH_OR_GLOB          drop a rule      --prefs-show   list the rules
  --publish-repo OWNER/REPO      where scripts/publish.sh pushes updates to this skill (leave unset to never publish)

Sizes are space used on disk. The scan never follows symlinks or leaves the filesystem it
starts on, reads no file contents, and deletes nothing. Run as your own user, not root.
Package modes need pacman (Arch); --scan works on any Linux.
"""

import subprocess, sys, os, glob, re, argparse, stat, json, fnmatch

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Where revisionN.txt live; --state-dir changes it (default: next to the script).
STATE_DIR = SCRIPT_DIR

# ── what the user wants kept ──────────────────────────────────────────────────

PREFS_PATH = os.path.expanduser(os.environ.get("PKGFILTER_PREFS", "~/.config/pkgfilter/prefs.json"))
PREFS = {"keep": [], "caution": [], "packages": [], "publish": ""}

def load_prefs():
    global PREFS
    try:
        with open(PREFS_PATH) as f:
            data = json.load(f)
    except (OSError, ValueError):
        data = {}
    PREFS = {k: data.get(k, []) for k in ("keep", "caution", "packages")}
    PREFS["publish"] = data.get("publish", "")

def save_prefs():
    os.makedirs(os.path.dirname(PREFS_PATH), exist_ok=True)
    with open(PREFS_PATH, "w") as f:
        json.dump(PREFS, f, indent=2)
        f.write("\n")

def _abs(p):
    return os.path.abspath(os.path.expanduser(p))

def _tilde(p):
    home = os.path.expanduser("~")
    return "~" + p[len(home):] if p == home or p.startswith(home + "/") else p

def path_tag(path):
    """KEEP / CAUTION for a path that is, or is inside, a protected folder; 'holds KEEP' for one that contains it."""
    ap = _abs(path)
    for level in ("keep", "caution"):
        for e in PREFS[level]:
            base = _abs(e["path"]).rstrip("/")
            if ap == base or ap.startswith(base + "/"):
                return level.upper()
    for e in PREFS["keep"]:
        if _abs(e["path"]).startswith(ap.rstrip("/") + "/"):
            return "holds KEEP"
    return ""

def pkg_tag(name):
    for level in ("keep", "caution"):
        for e in PREFS["packages"]:
            if e.get("level") == level and fnmatch.fnmatch(name, e["match"]):
                return level.upper()
    return ""

def add_pref(kind, target, reason):
    if kind in ("keep", "caution"):
        target = _tilde(_abs(target))
        PREFS["keep"] = [e for e in PREFS["keep"] if e["path"] != target]
        PREFS["caution"] = [e for e in PREFS["caution"] if e["path"] != target]
        PREFS[kind].append({"path": target, "reason": reason or ""})
    else:
        level = kind.split("-")[0]
        PREFS["packages"] = [e for e in PREFS["packages"] if e["match"] != target]
        PREFS["packages"].append({"match": target, "level": level, "reason": reason or ""})
    save_prefs()
    print(f"  Saved: {kind} {target}" + (f"  ({reason})" if reason else ""))

def forget_pref(target):
    t = _tilde(_abs(target)) if ("/" in target or target.startswith("~")) else target
    n = 0
    for k in ("keep", "caution"):
        before = len(PREFS[k]); PREFS[k] = [e for e in PREFS[k] if e["path"] != t]; n += before - len(PREFS[k])
    before = len(PREFS["packages"]); PREFS["packages"] = [e for e in PREFS["packages"] if e["match"] != target]; n += before - len(PREFS["packages"])
    save_prefs()
    print(f"  Removed {n} rule(s) for {target}")

def show_prefs():
    print(f"  Rules in {PREFS_PATH}")
    for level in ("keep", "caution"):
        for e in PREFS[level]:
            print(f"    {level.upper():8} {e['path']:<34} {e.get('reason', '')}")
    for e in PREFS["packages"]:
        print(f"    {e['level'].upper():8} pkg {e['match']:<30} {e.get('reason', '')}")
    if PREFS["publish"]:
        print(f"    PUBLISH  updates to this skill may be pushed to {PREFS['publish']}")
    if not any(PREFS.values()):
        print("    (none yet)")

# ── size helpers ──────────────────────────────────────────────────────────────

UNIT_TO_BYTES = {"b": 1, "kib": 1024, "mib": 1024**2, "gib": 1024**3}

def size_str_to_bytes(s):
    parts = s.strip().split()
    if len(parts) != 2:
        return 0
    try:
        return int(float(parts[0]) * UNIT_TO_BYTES.get(parts[1].lower(), 1))
    except ValueError:
        return 0

def bytes_to_human(n):
    for unit in ("GiB", "MiB", "KiB", "B"):
        d = UNIT_TO_BYTES[unit.lower()]
        if n >= d:
            return f"{n / d:.2f} {unit}"
    return f"{n} B"

def parse_size_arg(raw):
    m = re.match(r"^([0-9]*\.?[0-9]+)\s*([a-zA-Z]+)$", raw.strip())
    if not m:
        return 0
    return size_str_to_bytes(f"{m.group(1)} {m.group(2)}")

def query_sizes(packages):
    if not packages:
        return {}
    result = subprocess.run(["pacman", "-Qi"] + packages, capture_output=True, text=True)
    sizes, current_name = {}, None
    for line in result.stdout.splitlines():
        nm = re.match(r"^Name\s*:\s*(.+)", line)
        sm = re.match(r"^Installed Size\s*:\s*(.+)", line)
        if nm:
            current_name = nm.group(1).strip()
        elif sm and current_name:
            sizes[current_name] = size_str_to_bytes(sm.group(1).strip())
            current_name = None
    for p in packages:
        sizes.setdefault(p, 0)
    return sizes

# ── revision file helpers ─────────────────────────────────────────────────────

def save_revision(packages, sizes, rev_num):
    path = os.path.join(STATE_DIR, f"revision{rev_num}.txt")
    with open(path, "w") as f:
        for p in packages:
            f.write(f"{p}\t{sizes.get(p, 0)}\n")
    return path

def load_revision(path):
    packages, sizes = [], {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split("\t", 1)
            pkg = parts[0]
            packages.append(pkg)
            sizes[pkg] = int(parts[1]) if len(parts) == 2 else 0
    return packages, sizes

def latest_revision_number():
    nums = []
    for f in glob.glob(os.path.join(STATE_DIR, "revision*.txt")):
        try:
            nums.append(int(os.path.basename(f).replace("revision","").replace(".txt","")))
        except ValueError:
            pass
    return max(nums) if nums else 0

# ── display ───────────────────────────────────────────────────────────────────

def print_header(rev_num):
    next_rev = (rev_num + 1) if rev_num > 0 else 2
    src = f"revision{rev_num}.txt" if rev_num > 0 else "pacman -Qq  (first run)"
    running_as = "root (sudo)" if os.geteuid() == 0 else os.environ.get("USER", "user")
    print("=" * 54)
    print("  pkgfilter  —  Arch bloat hunter")
    print(f"  Running as : {running_as}")
    print(f"  Source     : {src}")
    print(f"  Output     : revision{next_rev}.txt")
    print("─" * 54)
    print("  Flags: -k WORD   keyword to strip")
    print("         -s SIZE   min size to keep  (e.g. 5MiB)")
    print("         -k plasma -s 10MiB  (combine)")
    print("=" * 54)
    print()

def print_package_table(packages, sizes, title=""):
    if not packages:
        print("  (no packages remaining)\n")
        return
    sorted_pkgs = sorted(packages, key=lambda p: sizes.get(p, 0), reverse=True)
    total = sum(sizes.get(p, 0) for p in packages)
    col_w = max(len(p) for p in packages) + 2
    if title:
        print(f"\n{title}")
        print("─" * (col_w + 14))
    print(f"  {'Package':<{col_w}} {'Size':>10}")
    print(f"  {'─'*col_w} {'─'*10}")
    for p in sorted_pkgs:
        print(f"  {p:<{col_w}} {bytes_to_human(sizes.get(p, 0)):>10}  {pkg_tag(p)}".rstrip())
    print(f"  {'─'*col_w} {'─'*10}")
    print(f"  {'TOTAL':<{col_w}} {bytes_to_human(total):>10}")
    print()

# ── filesystem scanner ────────────────────────────────────────────────────────

def real_home():
    """
    Return the actual user's home even when running under sudo.
    SUDO_USER is set by sudo to the original username.
    """
    sudo_user = os.environ.get("SUDO_USER")
    if sudo_user:
        import pwd
        try:
            return pwd.getpwnam(sudo_user).pw_dir
        except KeyError:
            pass
    return os.path.expanduser("~")

def scan_filesystem(scan_path, top_n=20, children=False):
    """
    Largest directories and files under scan_path, by space used on disk (blocks, so a sparse
    file counts for what it takes). Symlinks are not followed and other filesystems are not
    entered. Only the top N files are kept, so a big tree does not fill memory.
    With children=True, lists the immediate children of scan_path instead (a drill-down).
    """
    import heapq
    scan_path = os.path.abspath(scan_path)
    if not os.path.isdir(scan_path):
        print(f"  Path not found: {scan_path}")
        return

    print(f"\n{'='*54}")
    print(f"  Filesystem scan: {scan_path}")
    print(f"{'='*54}")
    print("  Scanning... (may take a moment)\n")

    root_dev = os.lstat(scan_path).st_dev
    dir_sizes  = {}
    top_files  = []          # min-heap of (size, path)
    direct     = {}          # size of files directly in each directory
    skipped    = 0

    def onerror(_err):
        nonlocal skipped
        skipped += 1

    for dirpath, dirnames, filenames in os.walk(scan_path, followlinks=False, onerror=onerror):
        keep = []
        for d in dirnames:
            try:
                if os.lstat(os.path.join(dirpath, d)).st_dev == root_dev:
                    keep.append(d)
            except OSError:
                skipped += 1
        dirnames[:] = keep
        dir_total = 0
        for fname in filenames:
            fpath = os.path.join(dirpath, fname)
            try:
                st = os.lstat(fpath)
            except OSError:
                skipped += 1
                continue
            if not stat.S_ISREG(st.st_mode):
                continue
            sz = st.st_blocks * 512
            dir_total += sz
            if len(top_files) < top_n:
                heapq.heappush(top_files, (sz, fpath))
            elif sz > top_files[0][0]:
                heapq.heapreplace(top_files, (sz, fpath))
        direct[dirpath] = dir_total
        dir_sizes[dirpath] = dir_sizes.get(dirpath, 0) + dir_total
        parent = os.path.dirname(dirpath)
        while parent.startswith(scan_path) and parent != dirpath:
            dir_sizes[parent] = dir_sizes.get(parent, 0) + dir_total
            parent = os.path.dirname(parent)

    col = 50
    def fmt(path):
        d = path.replace(scan_path, scan_path.rstrip("/"))
        return ("..." + d[-(col-3):]) if len(d) > col else d

    def table(title, rows):
        print(title)
        print(f"  {'─'*col} {'─'*10}")
        print(f"  {'Path':<{col}} {'Size':>10}")
        print(f"  {'─'*col} {'─'*10}")
        for path, sz in rows:
            print(f"  {fmt(path):<{col}} {bytes_to_human(sz):>10}  {path_tag(path)}".rstrip())
        print()

    files_sorted = sorted(top_files, reverse=True)
    if children:
        rows = [(p, s) for p, s in dir_sizes.items() if os.path.dirname(p) == scan_path]
        loose = direct.get(scan_path, 0)
        if loose:
            rows.append((os.path.join(scan_path, "(files directly here)"), loose))
        rows.sort(key=lambda x: x[1], reverse=True)
        table(f"  Immediate children of {scan_path} (total {bytes_to_human(dir_sizes.get(scan_path, 0))}):", rows[:top_n])
    else:
        top_dirs = sorted([(p, s) for p, s in dir_sizes.items() if p != scan_path], key=lambda x: x[1], reverse=True)[:top_n]
        table(f"  Top {top_n} largest directories:", top_dirs)
        table(f"  Top {top_n} largest files:", files_sorted)
    if skipped:
        print(f"  ({skipped} entries could not be read and are not counted)\n")

def dir_bytes(path):
    total = 0
    for dp, _dn, fns in os.walk(path, followlinks=False):
        for f in fns:
            try:
                st = os.lstat(os.path.join(dp, f))
                total += st.st_blocks * 512
            except OSError:
                pass
    return total

def orphans():
    try:
        out = subprocess.run(["pacman", "-Qdtq"], capture_output=True, text=True).stdout
    except FileNotFoundError:
        print("  pacman not found (package modes need Arch)."); return
    names = [l.strip() for l in out.splitlines() if l.strip()]
    sizes = query_sizes(names)
    free = [n for n in names if not pkg_tag(n)]
    print_package_table(names, sizes, title=f"  {len(names)} orphaned packages (installed as dependencies, nothing needs them now)")
    print(f"  Not marked KEEP or CAUTION: {len(free)} packages, {bytes_to_human(sum(sizes.get(n, 0) for n in free))}")
    print("  Remove with:  sudo pacman -Rns <names>   (your terminal; check each with pacman -Qi first)\n")

def orphans_detail(sort="size"):
    """Orphans with what a decision needs: size, install date, repo or AUR, a rough class, description,
    and what `pacman -Rns` would actually remove with them (read-only)."""
    run = lambda cmd: subprocess.run(cmd, capture_output=True, text=True)
    try:
        names = [l.strip() for l in run(["pacman", "-Qdtq"]).stdout.splitlines() if l.strip()]
    except FileNotFoundError:
        print("  pacman not found (package modes need Arch)."); return
    if not names:
        print("  No orphans."); return
    foreign = set(run(["pacman", "-Qmq"]).stdout.split())
    info = {}
    exp = run(["expac", "--timefmt=%Y-%m-%d", "-Q", "%n\t%m\t%l\t%d"] + names)
    if exp.returncode == 0:
        for line in exp.stdout.splitlines():
            n, size, date, desc = (line.split("\t") + ["", "", ""])[:4]
            info[n] = (int(size or 0), date, desc)
    else:  # no expac: fall back to the plain sizes
        for n, sz in query_sizes(names).items():
            info[n] = (sz, "?", "")
    def klass(n):
        if n.endswith("-debug") or n.endswith("-docs") or n.endswith("-doc"):
            return "debug/docs"
        if n.startswith("python-") or n.startswith("python3-"):
            return "python lib"
        if n.startswith("lib") or n.endswith("-libs"):
            return "library"
        return "other"
    rows = sorted(names, key=(lambda n: info.get(n, (0, "", ""))[1]) if sort == "date" else (lambda n: -info.get(n, (0, "", ""))[0]))
    print(f"\n  {len(names)} orphans, sorted by {sort}. Installed as dependencies; nothing installed needs or optionally uses them.")
    print(f"  {'package':32} {'size':>10}  {'installed':10}  {'src':4}  {'class':10}  description")
    for n in rows:
        sz, date, desc = info.get(n, (0, "?", ""))
        tag = pkg_tag(n)
        print(f"  {n:32} {bytes_to_human(sz):>10}  {date:10}  {'AUR' if n in foreign else 'repo':4}  {klass(n):10}  {(('[' + tag + '] ') if tag else '') + desc[:60]}")
    # what removing the unprotected ones would really take with it
    free = [n for n in rows if not pkg_tag(n)]
    pr = run(["pacman", "-Rs", "--print", "--print-format", "%n"] + free)
    would = [l.strip() for l in pr.stdout.splitlines() if l.strip()] if pr.returncode == 0 else []
    extra = [n for n in would if n not in names]
    print(f"\n  Unprotected: {len(free)} packages, {bytes_to_human(sum(info.get(n, (0,))[0] for n in free))}.")
    if pr.returncode != 0:
        print("  (pacman -Rns --print failed; check the names by hand: " + (pr.stderr.strip().splitlines() or ["no error text"])[-1][:100] + ")")
    elif extra:
        print(f"  Heads-up: `pacman -Rns` on all of them would ALSO remove {len(extra)} package(s) not in this list: {', '.join(extra[:12])}")
    else:
        print("  `pacman -Rns` on all of them removes only these (nothing extra).")
    print("  Orphans installed close together in date usually came from one project: use --orphans-sort date to see the groups.")
    print("  Why one was installed is not recorded by pacman; check `pacman -Qi <name>` and `pacman -Qo $(which <tool>)` if unsure. Remove in your terminal.\n")

def cache_report():
    cache = "/var/cache/pacman/pkg"
    print(f"\n  pacman cache {cache}: {bytes_to_human(dir_bytes(cache)) if os.path.isdir(cache) else 'missing'}")
    for label, args in (("keep the last 2 versions", ["-d", "-k2"]), ("keep only the latest version", ["-d", "-k1"]),
                        ("drop packages no longer installed", ["-d", "-u", "-k0"])):
        try:
            out = subprocess.run(["paccache"] + args, capture_output=True, text=True).stdout
        except FileNotFoundError:
            print("  paccache not found (pacman-contrib)."); break
        m = re.search(r"(\d+) candidates \(disk space saved: ([^)]+)\)", out)
        print(f"    {label:<40} {m.group(2) + ' (' + m.group(1) + ' files)' if m else 'nothing to remove'}")
    for d in ("~/.cache/yay", "~/.cache/paru"):
        d = os.path.expanduser(d)
        if os.path.isdir(d):
            print(f"  AUR build cache {d}: {bytes_to_human(dir_bytes(d))}")
    print("  Reclaim with:  sudo paccache -rk1   /   sudo paccache -ruk0   (your terminal). `pacman -Scc` also drops the")
    print("  versions you could downgrade to; yay -Sc clears the AUR build cache.\n")

# ── main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(add_help=True, description="Arch bloat hunter")
    parser.add_argument("-k", "--keyword", metavar="WORD",
                        help="strip packages whose name contains WORD")
    parser.add_argument("-s", "--minsize", metavar="SIZE",
                        help="drop packages smaller than SIZE (e.g. 5MiB, 500KiB)")
    parser.add_argument("--scan", nargs="?", const="", metavar="PATH",
                        help="scan PATH (default: your home) for the largest directories and files, then exit; asks nothing")
    parser.add_argument("--children", action="store_true",
                        help="with --scan: list the immediate children of PATH by size (drill down one level)")
    parser.add_argument("--top", type=int, default=20, metavar="N",
                        help="rows per table for --scan and --top-packages (default 20)")
    parser.add_argument("--top-packages", action="store_true",
                        help="show the largest packages of the current revision (or of pacman, on a first run) and exit; saves nothing")
    parser.add_argument("--state-dir", metavar="DIR",
                        help="where revisionN.txt are kept (default: next to this script)")
    parser.add_argument("--reset", action="store_true",
                        help="delete every revisionN.txt in the state dir, so the next run starts from pacman again")
    parser.add_argument("--orphans", action="store_true", help="packages nothing needs any more, with sizes (read-only)")
    parser.add_argument("--orphans-detail", action="store_true", help="orphans with install date, repo/AUR, class and what removing them would also take (read-only)")
    parser.add_argument("--orphans-sort", choices=["size", "date"], default="size", help="sort for --orphans-detail")
    parser.add_argument("--cache-report", action="store_true", help="pacman and yay cache sizes and what paccache could reclaim (read-only)")
    parser.add_argument("--keep", metavar="PATH", help="never touch PATH (saved in the prefs file)")
    parser.add_argument("--caution", metavar="PATH", help="only obvious bloat inside PATH (saved in the prefs file)")
    parser.add_argument("--keep-pkg", metavar="GLOB", help="never remove packages matching GLOB")
    parser.add_argument("--caution-pkg", metavar="GLOB", help="packages matching GLOB need a reason to remove")
    parser.add_argument("--reason", metavar="TEXT", help="why, with --keep/--caution/--keep-pkg/--caution-pkg")
    parser.add_argument("--forget", metavar="PATH_OR_GLOB", help="drop a saved rule")
    parser.add_argument("--prefs-show", action="store_true", help="list the saved rules")
    parser.add_argument("--publish-repo", metavar="OWNER/REPO", help="the GitHub repo this skill's updates are pushed to (yours; unset on anyone else's copy)")
    args = parser.parse_args()
    load_prefs()
    for flag, kind in (("keep", "keep"), ("caution", "caution"), ("keep_pkg", "keep-pkg"), ("caution_pkg", "caution-pkg")):
        if getattr(args, flag):
            add_pref(kind, getattr(args, flag), args.reason)
            return
    if args.publish_repo is not None:
        PREFS["publish"] = args.publish_repo
        save_prefs()
        print(f"  Publish repo: {args.publish_repo or '(none)'}")
        return
    if args.forget:
        forget_pref(args.forget)
        return
    if args.prefs_show:
        show_prefs()
        return
    if args.cache_report:
        cache_report()
        return
    if args.orphans:
        orphans()
        return
    if args.orphans_detail:
        orphans_detail(args.orphans_sort)
        return
    global STATE_DIR
    if args.state_dir:
        STATE_DIR = os.path.abspath(os.path.expanduser(args.state_dir))
        os.makedirs(STATE_DIR, exist_ok=True)

    if args.reset:
        gone = glob.glob(os.path.join(STATE_DIR, "revision*.txt"))
        for f in gone:
            os.remove(f)
        print(f"  Removed {len(gone)} revision file(s) from {STATE_DIR}")
        return
    if args.scan is not None:
        scan_filesystem(args.scan or real_home(), args.top, args.children)
        return
    if args.top_packages:
        rev = latest_revision_number()
        if rev:
            pkgs, sz = load_revision(os.path.join(STATE_DIR, f"revision{rev}.txt"))
            src = f"revision{rev}.txt"
        else:
            out = subprocess.run(["pacman", "-Qq"], capture_output=True, text=True, check=True).stdout
            pkgs = [l.strip() for l in out.splitlines() if l.strip()]
            sz = query_sizes(pkgs)
            src = "pacman (nothing saved)"
        top = sorted(pkgs, key=lambda p: sz.get(p, 0), reverse=True)[:args.top]
        print_package_table(top, sz, title=f"  Largest {len(top)} of {len(pkgs)} packages ({src})")
        return
    non_interactive = args.keyword is not None or args.minsize is not None

    rev_num = latest_revision_number()
    print_header(rev_num)

    # ── Step 1: load packages ─────────────────────────────────────────────────
    if rev_num == 0:
        print("First run — querying pacman for installed packages...")
        try:
            result = subprocess.run(
                ["pacman", "-Qq"], capture_output=True, text=True, check=True
            )
        except FileNotFoundError:
            print("ERROR: pacman not found. Are you on Arch Linux?", file=sys.stderr)
            sys.exit(1)
        except subprocess.CalledProcessError as e:
            print(f"ERROR: pacman -Qq failed\n{e.stderr}", file=sys.stderr)
            sys.exit(1)

        packages = [l.strip() for l in result.stdout.splitlines() if l.strip()]
        print(f"  {len(packages)} packages found.")
        print("  Querying installed sizes via pacman -Qi (may take a moment)...")
        sizes = query_sizes(packages)
        save_revision(packages, sizes, 1)
        print(f"  Base list saved → revision1.txt\n")
        current_rev = 1
    else:
        path = os.path.join(STATE_DIR, f"revision{rev_num}.txt")
        packages, sizes = load_revision(path)
        print(f"  {len(packages)} packages loaded from revision{rev_num}.txt\n")
        current_rev = rev_num

    # ── Step 2: keyword filter ────────────────────────────────────────────────
    if non_interactive:
        keyword = args.keyword
        if keyword:
            kw_lower = keyword.lower()
            removed  = [p for p in packages if kw_lower in p.lower()]
            packages = [p for p in packages if kw_lower not in p.lower()]
            print(f"  Keyword '{keyword}' — removed {len(removed)} package(s):")
            for p in removed:
                print(f"    - {p}  ({bytes_to_human(sizes.get(p, 0))})")
        else:
            print("  No keyword — skipping.")
    else:
        print("  Enter one or more space-separated keywords to strip matching packages.")
        print("  e.g.  plasma kde qt      strips all three in one go")
        print("  Blank or 'quit' to move on.\n")
        total_removed = 0
        while True:
            raw = input(f"  Keywords [{len(packages)} remaining] (quit to stop): ").strip()
            if not raw or raw.lower() == "quit":
                break
            keywords = raw.split()
            round_removed = 0
            for keyword in keywords:
                kw_lower = keyword.lower()
                removed  = [p for p in packages if kw_lower in p.lower()]
                if not removed:
                    print(f"    '{keyword}' — no matches")
                    continue
                packages = [p for p in packages if kw_lower not in p.lower()]
                total_removed  += len(removed)
                round_removed  += len(removed)
                print(f"    '{keyword}' — removed {len(removed)}:")
                for p in removed:
                    print(f"      - {p}  ({bytes_to_human(sizes.get(p, 0))})")
            if len(keywords) > 1 and round_removed:
                print(f"    [{round_removed} removed this pass, {len(packages)} remaining]")
            print()
        if total_removed:
            print(f"\n  Keywords done — {total_removed} packages removed total.\n")

    # ── Step 3: size filter ───────────────────────────────────────────────────
    size_raw = args.minsize
    if size_raw is None and not non_interactive:
        print("  Size filter — drop packages smaller than a threshold.")
        print("  Accepts: 5MiB  500KiB  1GiB   (blank to skip)\n")
        size_raw = input("  Minimum size to keep: ").strip()

    if size_raw:
        threshold = parse_size_arg(size_raw)
        if threshold == 0:
            print(f"  Couldn't parse '{size_raw}' — skipping size filter.")
        else:
            too_small = [p for p in packages if sizes.get(p, 0) < threshold]
            packages  = [p for p in packages if sizes.get(p, 0) >= threshold]
            print(f"\n  Size threshold ≥ {bytes_to_human(threshold)}"
                  f" — removed {len(too_small)} packages below threshold.")
    else:
        print("  No size filter.")

    # ── Step 4: save + show package table ────────────────────────────────────
    next_rev = current_rev + 1
    out_path = save_revision(packages, sizes, next_rev)
    print_package_table(
        packages, sizes,
        title=f"  revision{next_rev} — {len(packages)} packages remaining (largest first)"
    )
    print(f"  Saved → {os.path.basename(out_path)}  (revision{current_rev} → {next_rev})")

    # ── Step 5: optional filesystem scan ─────────────────────────────────────
    if not non_interactive:
        print()
        do_scan = input("  Scan filesystem for large files/folders? [y/N]: ").strip().lower()
        if do_scan == "y":
            home = real_home()
            path_input = input(
                f"  Path to scan (Enter for {home}, or type a path like / or /var): "
            ).strip()
            scan_path = path_input if path_input else home
            scan_filesystem(scan_path)

if __name__ == "__main__":
    main()
