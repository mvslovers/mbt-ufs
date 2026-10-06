-- mbt-ufs: build a UFS370 disk image from a directory, as an mbt task.
--
--   [plugins]
--   "mvslovers/mbt-ufs" = "^0.1"
--   [tools]
--   ufsd-utils = { repo = "mvslovers/ufsd-utils", version = "1.0.1" }
--
--   -- mbt/init.lua
--   local ufs = require("mvslovers/mbt-ufs")
--   ufs.webroot { from = "static", image = "build/webroot/httpd-webroot.img" }
--
-- The project pins ufsd-utils itself ([tools]): the plugin names the tool,
-- the project decides which release of it builds its images.

local M = {}

local defaults = {
  name    = "webroot",
  size    = "1M",
  blksize = "4096",
  owner   = "IBMUSER",
  group   = "SYSPROG",
  before  = { "package", "dist" },
  tool    = "ufsd-utils",
}

local function opt(spec, k)
  if spec[k] ~= nil then return spec[k] end
  return defaults[k]
end

-- webroot registers a task that builds spec.image from the files in
-- spec.from: created empty, then everything below spec.from copied in.
function M.webroot(spec)
  assert(type(spec) == "table", "mbt-ufs: webroot { from = ..., image = ... }")
  assert(spec.from and spec.image, "mbt-ufs: webroot needs from and image")
  mbt.task {
    name        = opt(spec, "name"),
    description = ("UFS image %s, from %s/"):format(spec.image, spec.from),
    before      = opt(spec, "before"),
    inputs      = { spec.from },
    outputs     = { spec.image },
    run = function(ctx)
      local ufs, img = ctx.tool(opt(spec, "tool")), ctx.out[1]
      ctx.exec { ufs, "create", img, "--size", opt(spec, "size"), "--blksize", opt(spec, "blksize"),
                 "--owner", opt(spec, "owner"), "--group", opt(spec, "group") }
      ctx.exec { ufs, "cp", "-r", spec.from .. "/", img .. ":/" }
    end,
  }
end

return M
