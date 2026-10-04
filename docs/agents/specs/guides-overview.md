# Guides Spec: Overview

Spec for epic #39 (portable user guides for Vault). Written by #40.

This is a working document for epic #39, removed by #48. Precedence, deviations and removal
follow the [spec hub](../specs.md).

| File | Contents |
|------|----------|
| [guides-overview.md](guides-overview.md) | Goals, out of scope, paths, ownership, compatibility, sub-issue map, open points. |
| [guides-pages.md](guides-pages.md) | Audience and style, page list and per-page content, ports, image tags. |
| [guides-portability.md](guides-portability.md) | Portability rules, version line, link check contract, edge cases. |
| [guides-readme.md](guides-readme.md) | README split: which sections move to which page, what the README keeps, links to update. |

Whoever adds, merges or renumbers sub-issues of #39 updates the [sub-issue map](#sub-issue-map).

## Goals

- Give projects that ship their application with Vault a set of guides they can **copy by
  hand** into their own repository.
- The copied guides keep working: links stay relative inside the tree, nothing depends on
  files that only exist in the Vault repository.
- One place to maintain detailed usage: the README keeps an overview and links to the guides.
- A stable local reference that a consumer repo's `AGENTS.md` can point AI agents at.

## Out of scope

- Shipping the guides in the image, installing them with `install.sh` / `vault-install`, or
  attaching them to the GitHub release. Copying is manual.
- An "upgrading Vault" guide.
- Any change to the behaviour of the image or the CLI.
- Translations.

## Paths

| Path | Contents |
|------|----------|
| `docs/guides/vault.md` | Index: what Vault is, when to use it, choosing a path, page index, version line. |
| `docs/guides/vault/*.md` | Topic pages (list in [guides-pages.md](guides-pages.md)). |

- The **copy unit** is the whole `docs/guides/` tree (`vault.md` + `vault/`).
- #41 created a minimal `docs/guides/vault.md` (top block and version line); #42 fills it.

## Agent ownership

| Agent | Owns (for #39) |
|-------|----------------|
| `product-owner` | `docs/agents/` (incl. `specs/`) **and `docs/guides/`** (portable user guides, copied by hand into consumer repos); this spec and its removal. |
| `automation` | The link-check script under `scripts/`, the Make target, CI wiring, the guides version line in `scripts/bump_version.sh` / `scripts/check_tag_version.sh`, `DOCKERHUB_DESCRIPTION.md` links. |
| `architect` | `README.md`, `AGENTS.md`, `.claude/agents/*.md` (the `product-owner` scope extension). |

An agent that needs a change outside its paths reports it to the owner.

## Backward compatibility

- Documentation, a version line, a script and a Make target only.
- No change to the image, the CLI, existing Make targets or the release chain. The PR job
  `build-and-test` gains the docs check.
- Links to README sections that move to the guides are updated (Docker Hub description, agent
  docs) in #47; see [guides-readme.md](guides-readme.md#links-to-update).

## Sub-issue map

| Sub-issue | Agents | Spec sections | Depends on |
|-----------|--------|---------------|------------|
| #40 Spec and `docs/guides/` ownership | `product-owner`, `architect` | This folder; [Agent ownership](#agent-ownership). | epic #20 closed |
| #41 Link check and version line | `automation` | [guides-portability.md → Version line](guides-portability.md#version-line), [→ Link check contract](guides-portability.md#link-check-contract). | #40 |
| #42 Index, concepts and security | `product-owner` | [guides-pages.md](guides-pages.md): `vault.md`, `concepts.md`, `security.md`, [Ports](guides-pages.md#ports); [guides-portability.md](guides-portability.md#portability-rules). | #40 (#41 recommended first) |
| #43 Image directly and as a base image | `product-owner` | [guides-pages.md](guides-pages.md): `docker-run.md`, `base-image.md`. | #42 |
| #44 The `vault` CLI | `product-owner` | [guides-pages.md](guides-pages.md): `cli.md`. | #42 |
| #45 Configuration, operations, troubleshooting | `product-owner` | [guides-pages.md](guides-pages.md): `configuration.md`, `operations.md`, `troubleshooting.md`. | #42 |
| #46 Examples and the agent snippet | `product-owner` | [guides-pages.md](guides-pages.md): `examples.md`, `agents-snippet.md`. | #43, #44, #45 |
| #47 README slim-down and links | `architect`, `product-owner`, `automation` | [guides-readme.md](guides-readme.md). | #42–#46 |
| #48 Remove the spec | `product-owner` | Deletes every `guides-*.md` file and the hub row. | #47 |

- #43, #44 and #45 can run in parallel once #42 has landed.
- Each page sub-issue also adds its page to the page index of `vault.md`.

## Open points

Each open point names the sub-issue that settles it; that sub-issue updates the spec.

| # | Open point | Proposed default | Settled by |
|---|------------|------------------|------------|
| 1 | Name of the link-check script. | `scripts/check_guides_links.sh`. | #41 |
| 2 | Whether the link check also runs on the README and `docs/agents/`. | No: `docs/guides/` only. | #41 |
| 3 | Whether `make test-docs` runs as part of `make test` or as its own CI step. | Its own step in `build-and-test`, next to `make lint` / `make test`. | #41 |
| 4 | Whether the version line lands before `docs/guides/vault.md` exists. | #41 creates a minimal `docs/guides/vault.md` holding only the top block and the version line if #42 has not landed; #42 fills it. | #41 |
| 5 | Exact wording of the `AGENTS.md` → Privileges rule once the Security details move to `security.md`. | The README keeps a short Security summary linking to `security.md`; the rule is reworded to say so. | #47 |
| 6 | Example compose files (images, versions) used in `examples.md`. | Public images (`postgres:17`, `redis:7`) and a placeholder `my-app` image. | #46 |
