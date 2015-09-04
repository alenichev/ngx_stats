local stats = ngx.shared.stats
local zone = ngx.var.zone or "default"

local status = "status_" .. ngx.var.status

local method = ngx.var.request_method or "BAD"
method = "request_method_" .. method:lower()

local proto = ngx.var.server_protocol
proto = "server_protocol_" .. proto:match("HTTP/(.*)")

local newval, err = stats:incr("requests:" .. zone, 1)
if not newval and err == "not found" then
    stats:add("requests:" .. zone, 0)
    stats:incr("requests:" .. zone, 1)
end

local newval, err = stats:incr(status .. ":" .. zone, 1)
if not newval and err == "not found" then
    stats:add(status .. ":" .. zone, 0)
    stats:incr(status .. ":" .. zone, 1)
end

local newval, err = stats:incr(method .. ":" .. zone, 1)
if not newval and err == "not found" then
    stats:add(method .. ":" .. zone, 0)
    stats:incr(method .. ":" .. zone, 1)
end

local newval, err = stats:incr(proto .. ":" .. zone, 1)
if not newval and err == "not found" then
    stats:add(proto .. ":" .. zone, 0)
    stats:incr(proto .. ":" .. zone, 1)
end

local bytes = stats:get("bytes_sent:" .. zone) or 0
bytes = bytes + tonumber(ngx.var.bytes_sent)
stats:set("bytes_sent:" .. zone, bytes)

local request_time = stats:get("request_time:" .. zone) or 0
request_time = request_time + tonumber(ngx.var.request_time)
stats:set("request_time:" .. zone, request_time)
