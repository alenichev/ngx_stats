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
local status = tonumber(ngx.var.status)
counter(key("status_" .. status))
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
    end
else
    proto = "server_protocol_0.9"
end
counter(key(proto))

local cache_status = ngx.var.upstream_cache_status
if cache_status then
    counter(key("upstream_cache_status_" .. cache_status))
end

local upstream_addr = ngx.var.upstream_addr
if upstream_addr then
    local total_time = 0
    local connect_time = ngx.var.upstream_connect_time
    if connect_time then
        conn_time = connect_time:gmatch("([0-9%.]+),? ?:?")
    end
    local header_time = ngx.var.upstream_header_time
    if header_time then
        head_time = header_time:gmatch("([0-9%.]+),? ?:?")
    end
    local response_time = ngx.var.upstream_response_time
    if response_time then
        resp_time = response_time:gmatch("([0-9%.]+),? ?:?")
    end
    local upstream_status = ngx.var.upstream_status
    if upstream_status then
        up_status = upstream_status:gmatch("(%d+),? ?:?")
    end

    for addr in string.gmatch(upstream_addr, "([0-9a-zA-Z%.:/]+),? ?:?") do
        counter(key("upstream_requests"))
        counter(akey("upstream_requests", addr))
        if connect_time then
            local ctime = conn_time()
            sum(akey("upstream_connect_time", addr), ctime)
        end
        if header_time then
            local htime = head_time() or 0
            sum(akey("upstream_header_time", addr), htime)
        end
        if response_time then
            local rtime = resp_time() or 0
            sum(akey("upstream_response_time", addr), rtime)
            total_time = total_time + rtime
        end
        if upstream_status then
            local ustatus = up_status()
            if ustatus then
                counter(akey("upstream_status_" .. ustatus, addr))
            end
        end
        counter(key("next_upstream"))
    end

    sum(key("upstream_response_time"), total_time)
    stats:incr(key("next_upstream"), -1)
end
