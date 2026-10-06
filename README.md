# mbt-ufs

An [mbt 3](https://github.com/mvslovers/mbt) plugin: build a UFS370 disk
image from a directory, as a task that runs before `mbt package`. httpd uses
it for the webroot image its SMP package ships.

```toml
# mbt.toml
[plugins]
"mvslovers/mbt-ufs" = "^0.1"

[tools]
ufsd-utils = { repo = "mvslovers/ufsd-utils", version = "1.0.1" }
```

```lua
-- mbt/init.lua
local ufs = require("mvslovers/mbt-ufs")
ufs.webroot { from = "static", image = "build/webroot/httpd-webroot.img" }
```

`webroot` takes `from` and `image`, and optionally `name` (the task,
default `webroot`), `size` (`1M`), `blksize` (`4096`), `owner` (`IBMUSER`),
`group` (`SYSPROG`), `before` (`{ "package", "dist" }`) and `tool`
(`ufsd-utils`). The image is rebuilt when a file below `from` changes, and
skipped otherwise.

The project pins `ufsd-utils` in its own `[tools]`: the plugin names the
tool, the project decides which release builds its images. The plugin runs
nothing else (`plugin.toml`: `exec = ["ufsd-utils"]`), and mbt holds it to
that.

## Releasing

A tag `vX.Y.Z` builds `mbt-ufs-X.Y.Z-plugin.tar.gz` (`plugin.toml`,
`init.lua`, `lua/`, this README and a LICENSE) and attaches it to the
GitHub release, where mbt looks for it.
