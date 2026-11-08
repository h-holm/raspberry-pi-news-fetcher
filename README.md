# Raspberry Pi News Fetcher

[Bash scripts](./scripts) and cron jobs that turn a Raspberry Pi into a weekly newspaper delivery service for e-readers:

1. **Fetch:** [Calibre's `ebook-convert`](https://manual.calibre-ebook.com/generated/en/ebook-convert.html) scrapes news sources into EPUBs.
2. **Deliver:** for each reader, the right EPUBs are copied into a local folder, old issues are removed, and the folder is synced bidirectionally with the reader's Dropbox using [`rclone bisync`](https://rclone.org/bisync/).
3. **Read:** an e-reader with Dropbox integration (e.g. a [Kobo](https://help.kobo.com/hc/en-us/articles/360032442774-Kobo-Libra-H2O), which uses `Apps/Rakuten Kobo`) downloads the new issues.

```text
                      ┌───────────────────────┐
config/fetch.sources ─▶ scripts/fetch_news.sh │  Fridays, via cron
                      └───────────┬───────────┘
                                  ▼
                            fetched-news/  ─────────────▶ news-emailer (optional, separate repo)
                                  │
              scripts/run_reader.sh <reader>  (every 30 min, per reader)
              ├─ housekeep_news.sh: copy this reader's sources once, delete old issues
              └─ run_rclone_bisync.sh: local folder ⇄ Dropbox ⇄ e-reader
```

A source that fails to fetch never blocks the others. Whatever was fetched is still delivered, and failures are logged (and optionally emailed, see [Alerts](#alerts)).

## Requirements

Developed and run on a Raspberry Pi 4 (Raspberry Pi OS / Debian 13, aarch64). Anything Debian-like with GNU coreutils, util-linux (`flock`, `getopt`) and cron should work.

| Tool | Version on my Pi | Install |
|---|---|---|
| Bash | 5.2 | preinstalled (needs ≥ 4.4) |
| Calibre | 8.5 | `sudo apt install calibre` |
| rclone | 1.76 | see [rclone-setup.md](rclone-setup.md) (needs ≥ 1.66) |
| logrotate | 3.22 | `sudo apt install logrotate` |
| mutt (optional, alerts) | 2.2 | `sudo apt install mutt` |
| shellcheck, bats (development) | 0.10, 1.11 | `sudo apt install shellcheck bats` |

## Layout

```text
.
├── config/                 # Local configuration, gitignored except the *.example templates
│   ├── fetch.sources       # Every source to fetch, one per line
│   ├── notify.conf         # Optional alerting settings
│   └── readers/<name>.conf # One file per reader, plus a <name>.sources list
├── crontab.example         # The cron jobs to install
├── logrotate.conf.example  # Weekly log rotation, run from cron as the same user
├── recipes/                # Local Calibre recipes; <Source>.recipe overrides the built-in one
├── scripts/
│   ├── fetch_news.sh       # Fetches all sources into EPUBs
│   ├── housekeep_news.sh   # Delivers EPUBs to one reader folder and deletes old issues
│   ├── run_rclone_bisync.sh# Hardened rclone bisync of one reader folder
│   ├── run_reader.sh       # housekeep + bisync for one reader, from its config
│   ├── notify.sh           # Email/ntfy alerts (opt-in)
│   ├── status.sh           # Health overview
│   ├── update_recipe.sh    # Pulls the latest upstream version of a recipe
│   ├── test_recipe.sh      # Quick test of one recipe
│   └── lib/common.sh       # Shared helpers
├── tests/                  # bats tests (fake ebook-convert/rclone, no network)
└── hooks/pre-commit        # Blocks personal data/EPUBs from being committed
```

Runtime output (`fetched-news/`, `logs/`, `state/`) stays on the Pi and is never committed.

## Setup

```shell
git clone https://github.com/h-holm/raspberry-pi-news-fetcher.git ~/devel/raspberry-pi-news-fetcher
cd ~/devel/raspberry-pi-news-fetcher
git config core.hooksPath hooks      # enable the privacy pre-commit hook

cp config/fetch.sources.example config/fetch.sources                # then edit
cp config/readers/reader-a.conf.example config/readers/alice.conf   # one per reader
cp config/readers/reader-a.sources.example config/readers/alice.sources
cp logrotate.conf.example logrotate.conf                            # adjust the path if needed
```

Configure an rclone remote for each reader's Dropbox following [rclone-setup.md](rclone-setup.md). Then initialise the sync once per reader, which creates the `RCLONE_TEST` sentinel on both sides and runs the first resync:

```shell
scripts/run_rclone_bisync.sh --init -l ~/alice-dropbox-news -n alice-dropbox -r "Apps/Rakuten Kobo"
```

Finally, install the cron jobs from [crontab.example](crontab.example) with `crontab -e`, using one `run_reader.sh` line per reader.

### Adding a reader

Add `config/readers/<name>.conf` and `<name>.sources`, make sure their sources are in `config/fetch.sources`, set up the rclone remote, run the `--init` command above, and add a cron line. Check with `scripts/run_reader.sh <name> --dry-run -v`.

## Recipes

A source name is either the title of a [Calibre built-in recipe](https://github.com/kovidgoyal/calibre/tree/master/recipes) (`ebook-convert --list-recipes`) or `NAME`, for a local `recipes/NAME.recipe`. A local recipe takes precedence over a built-in one. That's useful because the Calibre in apt often ships outdated recipes.

```shell
scripts/update_recipe.sh Fokus                  # fetches upstream recipes/fokus.recipe
scripts/update_recipe.sh NZZ nzz_ger.recipe     # upstream file name differs from the source name
git diff recipes/ && scripts/test_recipe.sh NZZ && git commit -am "Update NZZ recipe"
```

Recipe history lives in git, so there's no need for dated backup copies. You can also [write your own recipe](https://manual.calibre-ebook.com/news_recipe.html).

## How deletion works

- `fetched-news/`: EPUBs older than `MAX_NUM_DAYS` are deleted, whatever their source.
- Reader folders: only files named like the fetcher's output, `<Source>-YYYY-MM-DD-HHMM.epub`, are ever deleted. Readers can keep their own books in the same Dropbox folder.
- Each issue is copied to a reader only once (a ledger lives in `state/`). If a reader deletes an issue, it is not copied back.

## Sync robustness

`rclone bisync` refuses to sync an empty folder, and used to require a manual `--resync` every time a reader folder briefly emptied between weekly issues. `run_rclone_bisync.sh` prevents and recovers from that:

- A `RCLONE_TEST` sentinel lives on both sides, checked with `--check-access`, so a folder is never empty. The Kobo ignores the file.
- If a side is *completely* empty (not even the sentinel), the script assumes a wipe and alerts instead of syncing.
- `--resilient --recover` let runs retry after transient errors. If bisync still demands a resync, the script runs one automatic `--resync-mode newer` and alerts. A resync only copies; it never deletes.

## Alerts

Copy `config/notify.conf.example` to `config/notify.conf` to get alerts by email (through mutt and your `~/.muttrc`) and/or [ntfy](https://ntfy.sh). You'll be alerted on failed sources and sync problems. Each distinct alert is sent at most once per 12 hours.

## Troubleshooting

```shell
scripts/status.sh                         # newest issue per reader, last sync, last failures
tail -n 50 logs/fetch_news.out            # last fetch run
ls logs/fetch/                            # full ebook-convert output of failed sources
scripts/test_recipe.sh "The Economist" -v # debug one recipe
scripts/run_reader.sh alice --dry-run -v  # what would the sync do?
```

- **`HTTP Error 403: Forbidden`**: the site blocks the recipe. Try `update_recipe.sh` with the latest upstream recipe.
- **Bisync aborts with "Must run --resync"**: the script retries with a resync automatically. If that also fails, run the command printed in the log by hand.

## Development

```shell
make check   # shellcheck + bats; run on the Pi or another GNU/Linux machine
```

macOS ships BSD tools and Bash 3.2, so run the tests on the Pi (or rely on CI). To deploy: merge to `main`, then `git pull` on the Pi. The Pi pulls over HTTPS and never pushes.

## Sending EPUBs by email

See the [News Emailer](https://github.com/h-holm/news-emailer) repo, which emails EPUBs from `fetched-news/` (e.g. to Kindle addresses) using Mutt.

## History

The Pi once couldn't run a recent Calibre, so for a while fetching ran in a container on [K3s](https://k3s.io) as a Kubernetes CronJob. See the [`k8s-cronjob` branch](https://github.com/h-holm/raspberry-pi-news-fetcher/tree/k8s-cronjob).
