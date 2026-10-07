-- mbt-ufs: build UFS370 disk images as mbt tasks.
--
--   [plugins]
--   "mvslovers/mbt-ufs" = "^0.1"
--   [tools]
--   ufsd-utils = { repo = "mvslovers/ufsd-utils", version = "1.0.1" }
--
--   -- mbt/init.lua
--   local ufs = require("mvslovers/mbt-ufs")
--   ufs.image   { name = "testdisk", image = "build/test.img", size = "2M", dirs = { "/tmp" } }
--   ufs.webroot { from = "static", image = "build/webroot/httpd-webroot.img" }
--
-- The project pins ufsd-utils itself ([tools]): the plugin names the tool,
-- the project decides which release of it builds its images.

local M = {}

local defaults = {
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

-- image registers a task that builds spec.image: created and formatted,
-- then the directories in spec.dirs made, then everything below spec.from
-- copied in. Both dirs and from are optional; without them the image is
-- empty.
function M.image(spec)
  assert(type(spec) == "table", "mbt-ufs: image { name = ..., image = ... }")
  assert(spec.name and spec.image, "mbt-ufs: image needs name and image")
  local what = spec.from and ("from %s/"):format(spec.from) or "empty"
  mbt.task {
    name        = spec.name,
    description = ("UFS image %s, %s"):format(spec.image, what),
    before      = opt(spec, "before"),
    inputs      = { spec.from },
    outputs     = { spec.image },
    run = function(ctx)
      local ufs, img = ctx.tool(opt(spec, "tool")), ctx.out[1]
      ctx.exec { ufs, "create", img, "--size", opt(spec, "size"), "--blksize", opt(spec, "blksize"),
                 "--owner", opt(spec, "owner"), "--group", opt(spec, "group") }
      for _, d in ipairs(spec.dirs or {}) do
        ctx.exec { ufs, "mkdir", img .. ":" .. d }
      end
      if spec.from then
        ctx.exec { ufs, "cp", "-r", spec.from .. "/", img .. ":/" }
      end
    end,
  }
end

-- webroot is image for a web server's document root: the task is called
-- "webroot" unless spec.name says otherwise, and spec.from is required.
function M.webroot(spec)
  assert(type(spec) == "table", "mbt-ufs: webroot { from = ..., image = ... }")
  assert(spec.from and spec.image, "mbt-ufs: webroot needs from and image")
  local s = {}
  for k, v in pairs(spec) do s[k] = v end
  s.name = s.name or "webroot"
  return M.image(s)
end

return M
