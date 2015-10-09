local stats = ngx.shared.stats
local keys = stats:get_keys(0)
table.sort(keys)

for k in pairs(keys) do
    ngx.say(ngx.var.msec .. " " .. keys[k] .. " " .. stats:get(keys[k]))
end
