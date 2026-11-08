# Improvement Plan: raspberry-pi-news-fetcher

> Living plan. Tick off phases as they land. Real reader names, remotes and emails are kept out of this public copy; the unscrubbed original lives at `~/.claude/plans/stateful-dancing-snail.md` on the Mac.

## Context

The repo has run on the Pi (`ssh pi@raspberrypi.local`, clone at `/home/pi/devel/raspberry-pi-news-fetcher`, on `main` @ `dfef66a`, same as local) for years. It is three Bash scripts driven by cron: `fetch_news.sh` (Calibre → EPUB, weekly on Friday 15:00), `housekeep_news.sh` (copies EPUBs to each reader's local Dropbox dir and deletes anything older than 6 days, every 10–30 min) and `run_rclone_bisync.sh` (Dropbox sync, every 30–60 min). The sibling repo `~/devel/news-emailer` reads `fetched-news/` too.

What I found on the Pi (2026-11-08):

**Silent failures happening right now**
- **Reader A's Dropbox sync has been broken since 2026-10-30, and Reader B's since 2026-03-29** (7+ months). Each run logs `Bisync aborted. Must run --resync to recover.` The cause: bisync refuses an *empty* listing. Housekeeping empties the local dir every week before Friday's fetch (Reader A's case, Path1 empty), or the reader empties the remote by deleting books on the Kobo (Reader B's case, Path2 empty). After that, every later run fails until someone runs `--resync` by hand. Reader C's sync works. The bash history shows `--resync` has been run by hand before.
- **The Economist and The Atlantic return `HTTP Error 403: Forbidden` every week.** They come from apt's Calibre 8.5 built-in recipes. Nothing alerts on this: `fetch_news.sh` exits 0 even when sources fail.
- **Orphan EPUBs are never deleted.** Housekeeping only deletes files whose name matches a *current* source, so `南方周末-2025-11-14-1500.epub` (59 MB) has sat in `fetched-news/` for a year.
- **`logs/` is 113 MB and grows without limit.** There is no rotation, and housekeeping logs about 10 lines every 10 minutes even when it does nothing ("Copied 8 EPUBs", which is untrue because `cp -n` skips files that already exist).

**Bugs in the scripts**
- `if [ ! command -v ebook-convert &> /dev/null ]` (`fetch_news.sh:89`, `run_rclone_bisync.sh:75`) is a broken `test` expression, so the dependency check never fires.
- `failures=$(echo "${failures}" | xargs)` (`fetch_news.sh:168`) squashes the list onto one line (`- The Economist - The Atlantic`) and breaks on quotes or apostrophes.
- `ebook-convert --list-recipes` runs once per source (slow). Calling it once and caching the output is enough.
- Housekeeping can copy a **partially written EPUB**: a fetch takes 7–12 min and housekeeping runs every 10 min. Nothing stops runs from overlapping (no `flock`).
- Unquoted `${SOURCES_FILE}` in `readarray` (`fetch_news.sh:99`). A blank line in a sources file would match every file in `find -name "**"`. A trailing slash in `--output-dir` from cron gives `//`.
- The README crontab example points to `/PATH/TO/REPO/fetch_news.sh` (missing `scripts/`).

**Maintainability**
- The three scripts repeat about 60% of their code (getopt boilerplate, usage, validation, logging).
- **Local recipes are gitignored** (`recipes/.gitignore` is `*`). They are versioned by hand as dated copies (`Fokus-20250511.recipe` …). The newest versions live only on the Pi (Pi `recipes/Fokus.recipe` and `NZZ.recipe` match none of the copies in the Mac's `rrecipes/`). Updating a recipe means copying it by hand from a Calibre clone.
- Per-reader setup is untracked and ad hoc: `READER-B-SOURCES`, `READER-C-SOURCES`, `FEW-SOURCES`, `SINGLE-SOURCE`, a modified `SOURCES`, and two near-identical crontab lines per reader.
- No lint, no tests, no CI.

## Decisions (agreed with user)
- **Keep bisync, but harden it** so it recovers on its own (no switch to one-way sync).
- **Per-reader config is gitignored local config.** Only templates/examples are tracked, and no personal data (email addresses etc.) goes to GitHub.
- **Stay in Bash** and refactor. No Python rewrite, and news-emailer is not merged in.
- Stay compatible with news-emailer: keep `fetched-news/` and the `<Source>-YYYY-MM-DD-HHMM.epub` naming.
- **Remove The Atlantic completely.** On the Pi it appears only in the fetch `SOURCES`, not in any reader's or news-emailer's list. **Keep The Economist** and let it keep failing for now.
- **Partial failures are fine.** A failing source must never stop the others from being fetched, delivered or synced. Failures are reported (log + notification), but they don't fail the run.
- **Everything must run on the Pi** (Debian 13 / Raspberry Pi OS, aarch64, bash 5.2, coreutils 9.7, rclone 1.71, util-linux `flock`). Only use tools from Debian's apt repos or ones already present. Checked on the Pi: `flock`, `timeout`, `mutt`, `make` and `curl` are installed. `logrotate`, `shellcheck` and `bats` are missing but available via apt (shellcheck 0.10.0, bats 1.11.1). No GNU-only flags beyond what coreutils 9.7 supports.

---

## Implementation status (2026-11-08, branch `improvements/robustness-refactor`)
Phases 1–8 are implemented. `make check` (shellcheck + 30 bats tests) passes on the Pi. **Live since 2026-11-08 03:09:** the Pi's clone is on this branch, the config is migrated into gitignored `config/` (3 readers), and the crontab now has 1 fetch line, 1 `run_reader.sh` line per reader and weekly logrotate. The news-emailer lines are unchanged, and the old crontab is in `~/crontab-backup-pre-golive-2026-11-08.txt`. **Completed 2026-11-08:** a full fetch → delivery → ntfy-alert cycle was verified on the live Pi, and the branch was merged to `main` (PR #10). The Pi runs `main`. ntfy alerts are enabled in the Pi's gitignored `config/notify.conf`, and The Economist keeps failing (accepted). The heading below says "branch `improvements/robustness-refactor`", but that branch is now merged and deleted. Possible follow-ups: try the latest upstream Economist recipe with `scripts/update_recipe.sh`.

Deviations from the plan, decided while implementing:
- **Target-dir cleanup** deletes old files matching the fetcher's naming `*-YYYY-MM-DD-HHMM.epub` for *any* source, not only the reader's current ones. This also cleans orphans when a source is dropped, and personal books never match the pattern. Tested.
- **`--force` is kept** (no `--max-delete 50`). Weekly rotation routinely deletes ≥50% of a small reader folder. Wipe protection comes from the sentinel instead: a missing `RCLONE_TEST` is only recreated on a side that still has other files, and a completely empty side aborts the run with an alert.
- **Delivery ledger added** (`state/delivered-*.txt`). Each issue is copied to a reader once, so an issue the reader deleted is not copied back every 10–30 minutes, as the old `cp -n` loop did.
- `--init` on `run_rclone_bisync.sh` creates sentinels on both sides and runs the initial `--resync-mode newer`.
- Notifications are deduplicated: the same subject is sent at most once per 12h.

## Phase −1: Back up, then update the Pi — ✅ DONE 2026-11-08 (rclone now v1.76.0, calibre still 8.5)
1. **Back up** to the Mac, run from the Mac. It covers both repos with their untracked config, recipes and logs, the crontab, rclone and mutt config (**contains secrets, so keep the archive private and out of git or cloud folders**), bisync state, and shell dotfiles:
   ```shell
   mkdir -p ~/Backups && ssh pi@raspberrypi.local \
     'crontab -l > ~/crontab-backup.txt && tar czf - -C /home/pi crontab-backup.txt devel .config/rclone .muttrc .mutt .cache/rclone/bisync .bashrc .profile dropbox-news reader-b-dropbox-news reader-c-dropbox-news' \
     > ~/Backups/rpi-news-$(date +%F).tar.gz
   tar tzf ~/Backups/rpi-news-$(date +%F).tar.gz | head   # verify
   ```
   The OS and packages are reinstallable from apt, so a file-level backup is enough. For a full image, power off and image the SD card on the Mac (e.g. Raspberry Pi Imager or `dd`). `dd` over SSH of a running system is not reliable.
2. **Update packages.** About 182 are upgradable. Back up first, and avoid Friday 14:30–16:30 so the fetch and emails aren't interrupted:
   ```shell
   sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
   sudo rclone selfupdate      # rclone came from rclone.org's install script, not apt
   sudo apt install -y logrotate shellcheck bats
   sudo reboot                 # if a kernel/firmware update was installed
   ```
   Afterwards, check `calibre --version`, `rclone --version` and `crontab -l`, and update the versions in the README.

## Phase P: Privacy audit and history rewrite — ✅ DONE 2026-11-08 (EPUBs removed, emails → noreply, force-pushed; Mac+Pi clones reset; pre-rewrite bundle in ~/Backups/. SHAs below are pre-rewrite; main is now e4ab0dd. Guardrails done; GitHub Support purge of PR refs dropped by decision 2026-11-08)
Audit of all 159 commits on all branches (2026-11-08). The repo is **already PUBLIC**, with 0 forks, 1 star and 9 PRs.
- **No secrets found.** No tokens, rclone config, app keys or recipe credentials. The CI workflows only reference `${{ secrets.* }}`. The committed `logs/run_rclonesync.out` was empty.
- **Found, and worth removing:**
  1. `fetched-news/人民日报-2022-01-31-2356.epub` (89 MB) and `fetched-news/FAZ.NET-2022-01-31-2356.epub` (0.8 MB), added in `2e42c0e` and removed in `5bd3e87`. These are scraped copyrighted newspaper content, and they make up almost all of the 86 MB pack.
  2. Author emails `<old-work-email>` (79 commits) and `<old-personal-email>` (72 commits). These are optional to rewrite: they have been public for years and may already be scraped. Rewrite them to `33653878+h-holm@users.noreply.github.com` if you want them gone.
- **Harmless, keep:** `/home/pi/...` paths, Docker Hub `henholm/...` image names, the remote name `dropbox-books-henrik` in old docs, and the Kobo model.
- **Rewrite steps** (on the Mac, in a fresh `git clone --mirror`. `brew install git-filter-repo`, or `apt install git-filter-repo` on the Pi):
  ```shell
  git clone --mirror git@github.com:h-holm/raspberry-pi-news-fetcher.git rpnf.git && cd rpnf.git
  git filter-repo --path-glob 'fetched-news/*.epub' --invert-paths
  # optional: add --mailmap my.mailmap  (lines: "Henrik Holm <33653878+h-holm@users.noreply.github.com> <<old-work-email>>", same for the other old email)
  git push --force --mirror   # rewrites main + k8s-cronjob
  ```
  Old SHAs stay reachable on GitHub through the 9 PRs' `refs/pull/*`. (Decided 2026-11-08: not worth it, skipped.) To purge them fully, one could open a GitHub Support "remove sensitive data / cached views" request after the push. Then, on the Pi and the Mac: `git fetch && git reset --hard origin/main`. Untracked config, logs and recipes survive this. Back up first (Phase −1).
  Commit dates and authorship are kept, but every SHA changes, which breaks PR links to commits.
- **Guardrails going forward:**
  - Set the noreply email for this repo: `git config user.email 33653878+h-holm@users.noreply.github.com`, on both the Mac and the Pi.
  - `.gitignore` covers `config/*` except `*.example`, plus `*.epub`, `logs/`, `fetched-news/` and `rpi-bash_history` (Phase 1).
  - Add a tracked `hooks/pre-commit` (enabled with `git config core.hooksPath hooks`) that runs `gitleaks protect --staged` (apt `gitleaks` 8.16 is available on the Pi) and rejects staged `*.epub`, `config/` files or email-like strings outside the example files. Run the same gitleaks check in CI.
  - Example configs, crontab examples and docs use placeholders only (`reader-a`, `you@example.com`). Never use real names or recipients, and don't copy anything from the news-emailer crontab lines.

## Phase 0: Ops triage on the Pi — mostly DONE 2026-11-08 (Atlantic removed, orphan deleted, logs archived to logs/archive/*.gz, reader A resynced, RCLONE_TEST added for readers A and C; reader B pending a decision: their remote is empty but 4 personal books remain locally)
0. Remove `The Atlantic` from the Pi's `SOURCES` (it is in no other list).
1. Inspect `rclone lsl` for both sides of the `reader-a-dropbox` and `reader-b-dropbox` remotes, then run `rclone bisync --resync --resync-mode newer -v <local> <remote>:"Apps/Rakuten Kobo"` for both.
2. Delete the orphan `fetched-news/南方周末-2025-11-14-1500.epub`.
3. Archive or truncate the current logs (gzip them to `logs/archive/`) before log rotation is introduced.

## Phase 1: Repo hygiene
- Add a root `.gitignore` covering `.DS_Store`, `logs/`, `fetched-news/`, `config/*` (except `*.example`) and `rpi-bash_history`.
- Delete the stray `.DS_Store` files. Do **not** commit `rpi-bash_history`; delete it locally once this plan is done.
- **Track recipes in git.** Change `recipes/.gitignore` to allow `*.recipe`, then commit the **Pi's** current `Fokus.recipe` and `NZZ.recipe` (the newest ones). Optionally commit the older `rrecipes/*-YYYYMMDD.recipe` files first as history, oldest to newest, so `git log -p recipes/` replaces the dated copies. Then delete `rrecipes/`.

## Phase 2: Shared library and script fixes
Create `scripts/lib/common.sh`, sourced by every script, containing:
- `set -euo pipefail`, plus `log()` / `warn()` / `die()` with ISO timestamps and stderr for errors
- `require_cmd <cmd>` (the correct `command -v` check)
- `read_sources <file>`: reads into an array, trims whitespace, skips blank lines and `#` comments, and dies if the result is empty
- `strip_trailing_slash`, and `with_lock <name>` using `flock -n` on `/tmp/news-fetcher-<name>.lock` (or `$XDG_RUNTIME_DIR`)

`fetch_news.sh`:
- Cache `ebook-convert --list-recipes` once.
- Write each EPUB to `${OUTPUT_DIR}/.partial/<name>.epub`, then `mv` it into place (atomic, so housekeeping and news-emailer never see partial files).
- Print failures as a proper multi-line list.
- **Tolerate partial failures:** keep going after a failing source and exit 0 if at least one source succeeded. Exit non-zero only if *every* source failed, or on a setup error (missing `ebook-convert`, bad args). Write failed sources to `logs/last_fetch_failures.txt` and hand them to `notify.sh` (Phase 6). Housekeeping, bisync and news-emailer run on their own crons, so each delivers whatever was fetched.
- `--timeout` per source, **default 10m** (decided 2026-11-08: 30m was too long; the slowest source observed takes ~2 min), so one hung site can't stall the run.

`housekeep_news.sh`:
- Wrap the run in `with_lock`.
- Copy with `cp -p --update=none` and count only files actually copied. Log only when something changes, plus a one-line summary.
- **Clean `--from-dir` by age for every `*.epub`, regardless of source** (fixes orphans; `fetched-news/` is owned by the fetcher).
- **`--target-dir` holds readers' OWN books too** (found 2026-11-08: one reader has 11 personal books there, another 4). Only ever delete files matching the fetcher's exact naming `<Source>-YYYY-MM-DD-HHMM.epub` for a known source — never all old `*.epub`. Add a bats test proving a personal book older than `--max-num-days` survives.
- Validate `--max-num-days` as an integer before using `-gt`.

`run_rclone_bisync.sh`: see Phase 3.

Keep every existing CLI flag working, so the current crontab keeps working during the rollout.

## Phase 3: Hardened bisync (`scripts/run_rclone_bisync.sh`)
- **Sentinel file on both sides:** make sure `RCLONE_TEST` exists locally and on the remote (`rclone touch`), and pass `--check-access`. Neither side can then ever be empty, which removes the root cause above. (Kobo ignores files that aren't books. Confirm once on the device.)
- Add `--resilient --recover --max-lock 15m --conflict-resolve newer` (all available in rclone v1.71.2 on the Pi).
- **Automatic recovery:** if bisync exits with "Must run --resync", log a loud warning and retry once with `--resync --resync-mode newer`.
- Drop the unconditional `--force`. Instead use `--max-delete 50` (a percentage), so a mistaken local wipe can't empty the Kobo.
- Add `with_lock`, and strip ANSI colour codes from the log (`--color NEVER`).

## Phase 4: Per-reader config and a single entry point
- `config/` is gitignored; `config/*.example` is tracked.
  - `config/fetch.sources`: everything to fetch. It is the union of all readers' sources plus news-emailer's needs, kept explicit.
  - `config/readers/<name>.conf`, as shell `KEY=value` files: `SOURCES_FILE`, `TARGET_DIR`, `RCLONE_REMOTE`, `REMOTE_DIR`, `MAX_NUM_DAYS`.
- New `scripts/run_reader.sh <name>` loads the conf, runs housekeep and then bisync.
- New tracked `crontab.example`: one fetch line and one `run_reader.sh` line per reader. Use `REPO=` and `PATH=` variables at the top so the lines stay short.
- **Migration on the Pi:** move the Pi's `SOURCES` → `config/fetch.sources`, `READER-B-SOURCES` / `READER-C-SOURCES` → `config/readers/*.sources`, and delete `FEW-SOURCES` / `SINGLE-SOURCE` if unused (ask). Then `git restore SOURCES` and remove the tracked root `SOURCES` (replaced by `config/fetch.sources.example`). Rewrite the crontab from `crontab.example` and keep the news-emailer lines as they are.

## Phase 5: Recipe maintenance
- New `scripts/update_recipe.sh <Name> [upstream-file]`: downloads `https://raw.githubusercontent.com/kovidgoyal/calibre/master/recipes/<file>.recipe` into `recipes/<Name>.recipe`. Review it with `git diff` and commit. This replaces the hand-made dated copies.
- The Economist: leave as is (failing) for now. Later, optionally try the latest upstream `economist.recipe` via `update_recipe.sh`.
- New `scripts/test_recipe.sh <Name>`: runs `ebook-convert <recipe> /tmp/x.epub --test -vv` for quick checks.

## Phase 6: Logging, rotation and alerting
- Make the scripts quiet by default (summary lines only) and add `-v` for detail. Redirect `ebook-convert` output to a per-run file, `logs/fetch/<timestamp>-<source>.log`, and keep it only for failures.
- Add a tracked `logrotate.conf.example` (weekly, rotate 8, compress, copytruncate) installed under `/etc/logrotate.d/` (needs sudo). Alternatively, a cron line running `logrotate -s state logrotate.conf` as user `pi`.
- **Alerting:** add `scripts/notify.sh`, called when one or more sources fail (one summary per run, not one per source) or when bisync fails or auto-resyncs. It sends mail through the mutt setup already on the Pi (`~/.muttrc` exists for news-emailer), with an optional ntfy URL. Set the address in gitignored `config/notify.conf`.
- Optionally add `scripts/status.sh`: last successful fetch and sync per reader, and the age of the newest EPUB in each target dir.

## Phase 7: Lint, tests, CI
- Add `shellcheck` across `scripts/**/*.sh` and fix the warnings.
- Add `bats` tests in `tests/`. Fake `ebook-convert` and `rclone` binaries on `PATH`, and temp dirs. Cover:
  - sources parsing (blank lines, comments, Unicode names)
  - local vs built-in recipe choice
  - partial failure (one fake source fails, the others still produce EPUBs, exit 0) and all-fail (non-zero)
  - housekeeping copy, age and orphan cleanup (`touch -d`)
  - bisync auto-resync path
  - locking
- Add a `Makefile` with `lint` and `test` targets, and a GitHub Actions workflow running both on push.

## Phase 8: Docs
- Rewrite the README around the new layout: overview diagram (fetch → fetched-news → per-reader dir → Dropbox → Kobo, plus news-emailer), quick start, config, adding a reader, adding or updating a recipe, troubleshooting (bisync resync, 403s), and deploying (`git pull` on the Pi).
- Fix the crontab paths. Move the outdated K8s section to a short "History" note.

## Critical files
- `scripts/fetch_news.sh`, `scripts/housekeep_news.sh`, `scripts/run_rclone_bisync.sh` (refactor)
- New: `scripts/lib/common.sh`, `scripts/run_reader.sh`, `scripts/update_recipe.sh`, `scripts/test_recipe.sh`, `scripts/notify.sh`, `crontab.example`, `config/*.example`, `logrotate.conf.example`, `.gitignore`, `tests/*.bats`, `Makefile`, `.github/workflows/ci.yml`
- `recipes/.gitignore` (un-ignore), `README.md`, `rclone-setup.md` (document the sentinel and `--check-access`)

## Rollout and verification
1. Develop on the Mac on a feature branch. **`make lint test` must pass on the Pi** (`git switch <branch>` there). The Mac and CI are a convenience only, because macOS ships BSD tools and bash 3.2.
2. On the Pi: `git fetch && git switch <branch>`. Run each script **by hand** with the old flags first, so the current crontab still works:
   - `fetch_news.sh` with a single-source file into a temp dir. Check the EPUB is created and the exit code is right.
   - `housekeep_news.sh` against a copy of a reader dir.
   - `run_rclone_bisync.sh --dry-run` per reader, then a real run. Check `RCLONE_TEST` exists on both sides and the log shows `Bisync successful`.
   - Simulate the failure: empty a scratch local dir and confirm bisync no longer aborts.
3. Switch the crontab to `crontab.example` (back up with `crontab -l > ~/crontab.bak`). Watch the logs over one Friday cycle. All readers should get new EPUBs, and the next Thursday/Friday "empty" window should pass without a resync error.
4. Merge to `main`, then `git pull` on the Pi.
