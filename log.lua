local stats = ngx.shared.stats
local zone = ngx.var.zone or "default"

local status = "status_" .. ngx.var.status

local method = ngx.var.request_method or "BAD"
method = "request_method_" .. method:lower()

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

local bytes = stats:get("bytes_sent:" .. zone) or 0
bytes = bytes + tonumber(ngx.var.bytes_sent)
stats:set("bytes_sent:" .. zone, bytes)

local request_time = stats:get("request_time:" .. zone) or 0
request_time = request_time + tonumber(ngx.var.request_time)
stats:set("request_time:" .. zone, request_time)

local proto = ngx.var.server_protocol
if proto then
    proto = "server_protocol_" .. proto:match("HTTP/(.*)")

    local newval, err = stats:incr(proto .. ":" .. zone, 1)
    if not newval and err == "not found" then
        stats:add(proto .. ":" .. zone, 0)
        stats:incr(proto .. ":" .. zone, 1)
    end
end

local upstream_addr = ngx.var.upstream_addr
if upstream_addr then
    local conn_time = ngx.var.upstream_connect_time:gmatch("([0-9%.]+),? ?:?")
    local head_time = ngx.var.upstream_header_time:gmatch("([0-9%.]+),? ?:?")
    local resp_time = ngx.var.upstream_response_time:gmatch("([0-9%.]+),? ?:?")

    for addr in string.gmatch(upstream_addr, "([0-9a-zA-Z%.:/]+),? ?:?") do
        local connect_time = "upstream_connect_time_" .. addr .. ":" .. zone
        local c_time = stats:get(connect_time) or 0
        c_time = c_time + conn_time()
        stats:set(connect_time, c_time)

        local header_time = "upstream_header_time_" .. addr .. ":" .. zone
        local h_time = stats:get(header_time) or 0
        h_time = h_time + head_time()
        stats:set(header_time, h_time)

        local response_time = "upstream_response_time_" .. addr .. ":" .. zone
        local r_time = stats:get(response_time) or 0
        r_time = r_time + resp_time()
        stats:set(response_time, r_time)
    end
end
