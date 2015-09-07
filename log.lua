local stats = ngx.shared.stats
local zone = ngx.var.zone or "default"

function key(name) return name .. ":" .. zone end

local status = "status_" .. ngx.var.status

local method = ngx.var.request_method or "BAD"
method = "request_method_" .. method:lower()

local newval, err = stats:incr(key("requests"), 1)
if not newval and err == "not found" then
    stats:add(key("requests"), 0)
    stats:incr(key("requests"), 1)
end

local newval, err = stats:incr(key(status), 1)
if not newval and err == "not found" then
    stats:add(key(status), 0)
    stats:incr(key(status), 1)
end

local newval, err = stats:incr(key(method), 1)
if not newval and err == "not found" then
    stats:add(key(method), 0)
    stats:incr(key(method), 1)
end

local bytes = stats:get(key("bytes_sent")) or 0
bytes = bytes + tonumber(ngx.var.bytes_sent)
stats:set(key("bytes_sent"), bytes)

local request_time = stats:get(key("request_time")) or 0
request_time = request_time + tonumber(ngx.var.request_time)
stats:set(key("request_time"), request_time)

local proto = ngx.var.server_protocol
if proto then
    proto = "server_protocol_" .. proto:match("HTTP/(.*)")

    local newval, err = stats:incr(key(proto), 1)
    if not newval and err == "not found" then
        stats:add(key(proto), 0)
        stats:incr(key(proto), 1)
    end
end

local upstream_addr = ngx.var.upstream_addr
if upstream_addr then
    local conn_time = ngx.var.upstream_connect_time:gmatch("([0-9%.]+),? ?:?")
    local head_time = ngx.var.upstream_header_time:gmatch("([0-9%.]+),? ?:?")
    local resp_time = ngx.var.upstream_response_time:gmatch("([0-9%.]+),? ?:?")
    local up_status = ngx.var.upstream_status:gmatch("(%d+),? ?:?")

    for addr in string.gmatch(upstream_addr, "([0-9a-zA-Z%.:/]+),? ?:?") do
        local connect_time = key("upstream_connect_time_" .. addr)
        local c_time = stats:get(connect_time) or 0
        c_time = c_time + conn_time()
        stats:set(connect_time, c_time)

        local header_time = key("upstream_header_time_" .. addr)
        local h_time = stats:get(header_time) or 0
        h_time = h_time + head_time()
        stats:set(header_time, h_time)

        local response_time = key("upstream_response_time_" .. addr)
        local r_time = stats:get(response_time) or 0
        r_time = r_time + resp_time()
        stats:set(response_time, r_time)

        local upstream_key = "upstream_status_" .. up_status() .. "_" .. addr
        local newval, err = stats:incr(key(upstream_key), 1)
        if not newval and err == "not found" then
            stats:add(key(upstream_key), 0)
            stats:incr(key(upstream_key), 1)
        end
    end
end
