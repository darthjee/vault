# Plan: Reorder Dockerfile layers by change frequency

Issue: [68-reorder-dockerfile-layers-by-change-frequency.md](../../issues/68-reorder-dockerfile-layers-by-change-frequency.md)

## Overview
Reorder the `Dockerfile` so layers go from least to most frequently changing, with `COPY build/vault` as the last content layer, per [image-cache-dockerfile.md](../../specs/image-cache-dockerfile.md). Single owner: `dev`.

See [dev.md](dev.md) for the full plan.
