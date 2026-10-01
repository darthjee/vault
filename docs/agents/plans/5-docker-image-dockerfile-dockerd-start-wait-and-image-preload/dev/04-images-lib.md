# images.sh

Create `source/lib/images.sh` (flow step 4, edge cases 4–5):

- `images_load_dir <dir>`: return 0 silently when `<dir>` is missing or holds no `*.tar` files (handle the unmatched-glob case explicitly, e.g. with a `[ -e "$tar" ]` guard or a local `nullglob`). Otherwise run `docker load -i "$tar"` for each tarball in glob order. On the first failure, print a message naming the file to stderr (e.g. `failed to load image tarball: /vault/images/app.tar`) and return 1.
- Stopping dockerd after a failure is the entrypoint's job (step 05), not the library's.

Tests, `test/lib/images.bats` (stub `docker`; use `BATS_TEST_TMPDIR` for the directory):
- missing directory → 0, no `docker` call;
- empty directory, or only non-`.tar` files → 0, no `docker` call;
- two tarballs → both loaded, in order;
- `docker load` fails on one → 1, the message names the file.

## Files to Change
- `source/lib/images.sh` — new.
- `test/lib/images.bats` — new.
