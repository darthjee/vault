# Write examples.md
Create `docs/guides/vault/examples.md`: complete worked setups that a reader can copy whole.

Page shape:
- `# Examples` title, a short intro saying each setup has a `docker run` variant and a CLI
  variant, which port mapping each uses (`docker run` → `-p 8080:80`; CLI → default `3000:80`
  unless `-p` is given), that `my-app` is a placeholder for the reader's own app image
  (listening on `3000`), and that `darthjee/vault:<version>` is the tag placeholder. Link
  [concepts.md](concepts.md) for the underlying model.
- One `##` section per setup, in this order:
  1. **App + Postgres** — project tree, `docker-compose.yml` (`app: my-app`,
     `ports: ["80:3000"]`, `depends_on: db`, `DATABASE_URL` pointing at `db`; `db: postgres:17`
     with no published ports and an inner named volume for `/var/lib/postgresql/data`), the
     password coming from an env file kept out of git.
  2. **App + Redis** — same shape with `redis:7` (no published ports), `REDIS_URL` pointing at
     `redis`.
  3. **Multiple compose files** — `compose.yml` + `compose.prod.yml` (override e.g. image tag
     or env), selected with `COMPOSE_FILE=compose.yml:compose.prod.yml`; link
     [configuration.md → Multiple compose files](configuration.md#multiple-compose-files).
  4. **Baked image with offline preload** — project tree with `images/`, `docker save`
     commands, a `Dockerfile` (`FROM darthjee/vault:<version>`, `COPY . /vault`,
     `ENV COMPOSE_UP_ARGS="--pull never"`), `docker build -t my-app .`; link
     [base-image.md → Offline preload](base-image.md#offline-preload). Note the platform caveat
     (save images for the target `linux/amd64` / `linux/arm64`).
- Within each setup, use `###` subsections: the compose file(s) (with a `# /vault/...` path
  comment, as in `concepts.md`), **With docker run** (Sysbox command, plus one line pointing
  to the `--privileged` fallback in [docker-run.md → Runtime](docker-run.md#runtime) /
  [security.md](security.md)), **With the CLI** (`vault up ./my-stack`, or
  `vault up --image my-app` for the baked image), and **Result**: a small table of what is
  published (host URL per variant) and which volumes exist (the `docker run` named volume vs.
  the CLI's `vault-<name>-data`, plus the inner named volume inside it).
- Keep each setup self-contained but short; link to the topic pages for explanations instead
  of repeating them (stopping/logs → [operations.md](operations.md), errors →
  [troubleshooting.md](troubleshooting.md)).

Use only facts already stated in the existing guide pages (see the Context section of
[../product-owner.md](../product-owner.md)); do not invent flags or behaviour.

## Files to Change
- `docs/guides/vault/examples.md` — new page.
