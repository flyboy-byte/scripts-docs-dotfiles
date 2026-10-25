# utils

One-file utilities. Python 3 unless noted; none of them call a network service except the whitepaper formatter.

| File | What it does |
|---|---|
| [`pcapdroid_analyze.py`](pcapdroid_analyze.py) | Sorts a PCAPdroid CSV export into NORMAL / ELEVATED / CONCERN / UNKNOWN traffic, per app. |
| [`strip_passwords.py`](strip_passwords.py) | Turns a Google Passwords CSV export into a plain list of domains, dropping the credentials. |
| [`chat_compress.py`](chat_compress.py) | Shrinks an AI chat markdown export for re-upload. |
| [`teleprompter.py`](teleprompter.py) | Scrolling teleprompter for video scripts (tkinter). |
| [`whitepaper-formatter.html`](whitepaper-formatter.html) | Browser page that turns raw research text into a structured white paper with the Claude API, without rewriting it. |

---

## pcapdroid_analyze.py

Built-in host and port tables: CDNs and known services are normal, analytics and ad-tech are elevated, data brokers,
Tor and remote-access ports are a concern. The report is grep-friendly: a flagged breakdown per app, every domain, apps
by data volume, a port inventory, the raw flagged connections and the domains it couldn't classify.

```bash
python utils/pcapdroid_analyze.py capture.csv
python utils/pcapdroid_analyze.py capture.csv --days 3       # adds connections/day
python utils/pcapdroid_analyze.py capture.csv --out report.txt
python utils/pcapdroid_analyze.py capture.csv --json > r.json # for an LLM
```

## strip_passwords.py

Reads a Google Passwords export (`name,url,username,password`) and prints a deduped, sorted list of domains, so you
can audit which sites you have saved logins for without handling the credentials.

```bash
python utils/strip_passwords.py export.csv
python utils/strip_passwords.py export.csv domains.txt   # write to a file
```

> [!CAUTION]
> The export holds every password in plain text. Delete it when you're done, and never commit it.

## chat_compress.py

Strips images, links, horizontal rules and extra blank lines, then prints how much smaller the file got. No API calls.

```bash
python utils/chat_compress.py input.md
python utils/chat_compress.py input.md --output out.md
```

## teleprompter.py

Loads a text file, wraps it to the window and scrolls it up through a fixed focal zone, so your eyes stay near the
camera. Space plays and pauses, ↑/↓ change speed, +/− change font size, R restarts, Q quits.

```bash
python utils/teleprompter.py script.txt
```

## whitepaper-formatter.html

Adds a title, table of contents and headings without rewriting or reordering your text. Runs in the browser.

- **In claude.ai:** paste the file in as an artifact and leave the API key blank; your session handles auth.
- **Standalone:** open the file and paste your own Anthropic API key. It's used for that one request and never stored.
