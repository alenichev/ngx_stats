local stats = ngx.shared.stats
local zone = ngx.var.zone or "default"

function key(name) return name .. ":" .. zone end
function akey(name, addr) return key(name) .. "@" .. addr end

function counter(name)
    local newval, err = stats:incr(name, 1)
    if not newval and err == "not found" then
        stats:add(name, 0)
        stats:incr(name, 1)
    end
end

function sum(name, value)
    local num = stats:get(name) or 0
    num = num + tonumber(value)
    stats:set(name, num)
end

counter(key("requests"))
counter(key("status_" .. ngx.var.status))
sum(key("bytes_sent"), ngx.var.bytes_sent)
sum(key("request_time"), ngx.var.request_time)

local method = ngx.var.request_method or "BAD"
method = "request_method_" .. method:lower()
counter(key(method))

local proto = ngx.var.server_protocol
if proto then
    proto = proto:match("HTTP/(1%.[0-1])")
    if proto then
        proto = "server_protocol_" .. proto
        counter(key(proto))
    end
end

local cache_status = ngx.var.upstream_cache_status
if cache_status then
    counter(key("upstream_cache_status_" .. cache_status))
end

local upstream_addr = ngx.var.upstream_addr
if upstream_addr then
    local connect_time = ngx.var.upstream_connect_time
    if connect_time then
        local conn_time = connect_time:gmatch("([0-9%.]+),? ?:?")
    end
    local head_time = ngx.var.upstream_header_time:gmatch("([0-9%.]+),? ?:?")
    local resp_time = ngx.var.upstream_response_time:gmatch("([0-9%.]+),? ?:?")
    local up_status = ngx.var.upstream_status:gmatch("(%d+),? ?:?")

    for addr in string.gmatch(upstream_addr, "([0-9a-zA-Z%.:/]+),? ?:?") do
        counter(akey("upstream_requests", addr))
        if connect_time then
            sum(akey("upstream_connect_time", addr), conn_time())
        end
        sum(akey("upstream_header_time", addr), head_time())
        sum(akey("upstream_response_time", addr), resp_time())
        counter(akey("upstream_status_" .. up_status(), addr))
        counter(key("next_upstream"))
    end

    stats:incr(key("next_upstream"), -1)
end
