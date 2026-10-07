# mbt-ufs

An [mbt 3](https://github.com/mvslovers/mbt) plugin that builds **UFS370 disk
images** as part of a project's build: a web server's document root, a test
disk with a fixed directory layout, a disk shipped in an SMP package.

The images are made on the host with
[ufsd-utils](https://github.com/mvslovers/ufsd-utils) and read on MVS by
[ufsd](https://github.com/mvslovers/ufsd). Each image is an mbt task. It is
rebuilt when a file below its source directory changes and skipped
otherwise, so a project that ships a disk never has to remember to rebuild
it.

## Quick start

Declare the plugin and the tool that does the work in `mbt.toml`:

```toml
[plugins]
"mvslovers/mbt-ufs" = "^0.1"

[tools]
ufsd-utils = { repo = "mvslovers/ufsd-utils", version = "1.0.1" }
```

Describe the images in `mbt/init.lua`:

```lua
local ufs = require("mvslovers/mbt-ufs")

-- everything below static/ becomes the image's root directory
ufs.webroot { from = "static", image = "build/webroot/httpd-webroot.img" }
```

Then fetch the plugin and the tool once (this pins both in `mbt.lock`):

```sh
mbt deps
```

From then on `mbt package` and `mbt dist` build the image before they
package, and only when `static/` changed. To build it by hand, run the task
by name. `mbt run` always rebuilds:

```sh
mbt run webroot
```

## Functions

### `ufs.image { ... }`

Registers a task that builds one image. The image is created and formatted,
then the directories in `dirs` are made, then everything below `from` is
copied in. Without `dirs` and `from` the image is empty.

| Key       | Default                 | Meaning                                                        |
|-----------|-------------------------|----------------------------------------------------------------|
| `name`    | *required*              | the task's name (`mbt run <name>`)                             |
| `image`   | *required*              | the image file, relative to the project                        |
| `from`    | none                    | a directory whose contents become the image's root             |
| `dirs`    | none                    | directories to create, parents first: `{ "/tmp", "/tmp/a" }`   |
| `size`    | `"1M"`                  | the image size (`ufsd-utils create --size`)                    |
| `blksize` | `"4096"`                | the block size                                                 |
| `owner`   | `"IBMUSER"`             | owner of the root directory                                    |
| `group`   | `"SYSPROG"`             | group of the root directory                                    |
| `before`  | `{ "package", "dist" }` | the mbt commands that build the image first; `{}` for none     |
| `tool`    | `"ufsd-utils"`          | the `[tools]` entry to run                                     |

```lua
-- a scratch disk for the tests, with an empty /tmp
ufs.image { name = "testdisk", image = "build/test.img", size = "2M",
            dirs = { "/tmp" }, before = { "test" } }
```

### `ufs.webroot { ... }`

The same as `ufs.image`, for a document root. `from` is required, and the
task is called `webroot` unless `name` says otherwise.

## Versions and safety

- **The project pins the tool, not the plugin.** `[tools]` in your
  `mbt.toml` decides which release of ufsd-utils builds your images, and
  `mbt.lock` holds its checksum. A plugin update never changes it.
- **The plugin runs ufsd-utils and nothing else.** Its `plugin.toml` says
  `exec = ["ufsd-utils"]`, and mbt refuses any other program it tries to
  start.
- **The build stays offline.** `mbt deps` downloads the plugin and the tool.
  `mbt build`, `mbt package` and the rest only use what is staged in `.mbt/`.

## Working on the plugin

To try a local copy in a project without releasing it, point the project at
it in `.mbt/deps.local.toml` (not committed):

```toml
[override]
"mvslovers/mbt-ufs" = { path = "../mbt-ufs" }
```

A tag `vX.Y.Z` builds `mbt-ufs-X.Y.Z-plugin.tar.gz` (`plugin.toml`,
`init.lua`, `lua/` if present, this README and a LICENSE if present) and
attaches it to the GitHub release. That asset is what mbt resolves
`[plugins] "mvslovers/mbt-ufs"` against.
