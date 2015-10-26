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
if string.match(status, "^2.*") then
    counter(key("status_2xx"))
elseif string.match(status, "^3.*") then
    counter(key("status_3xx"))
elseif string.match(status, "^4.*") then
    counter(key("status_4xx"))
elseif string.match(status, "^5.*") then
    counter(key("status_5xx"))
end

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
            rtime = tonumber(rtime)
            sum(akey("upstream_response_time", addr), rtime)
            total_time = total_time + rtime
            if rtime > 0 and rtime < 0.01 then
                counter(akey("upstream_response_histogram_0000_to_0010", addr))
            elseif rtime > 0.01 and rtime < 0.02 then
                counter(akey("upstream_response_histogram_0010_to_0020", addr))
            elseif rtime > 0.02 and rtime < 0.03 then
                counter(akey("upstream_response_histogram_0020_to_0030", addr))
            elseif rtime > 0.03 and rtime < 0.04 then
                counter(akey("upstream_response_histogram_0030_to_0040", addr))
            elseif rtime > 0.04 and rtime < 0.05 then
                counter(akey("upstream_response_histogram_0040_to_0050", addr))
            elseif rtime > 0.05 and rtime < 0.06 then
                counter(akey("upstream_response_histogram_0050_to_0060", addr))
            elseif rtime > 0.06 and rtime < 0.07 then
                counter(akey("upstream_response_histogram_0060_to_0070", addr))
            elseif rtime > 0.07 and rtime < 0.08 then
                counter(akey("upstream_response_histogram_0070_to_0080", addr))
            elseif rtime > 0.08 and rtime < 0.09 then
                counter(akey("upstream_response_histogram_0080_to_0090", addr))
            elseif rtime > 0.09 and rtime < 0.1 then
                counter(akey("upstream_response_histogram_0090_to_0100", addr))
            elseif rtime > 0.1 and rtime < 0.2 then
                counter(akey("upstream_response_histogram_0100_to_0200", addr))
            elseif rtime > 0.2 and rtime < 0.3 then
                counter(akey("upstream_response_histogram_0200_to_0300", addr))
            elseif rtime > 0.3 and rtime < 0.4 then
                counter(akey("upstream_response_histogram_0300_to_0400", addr))
            elseif rtime > 0.4 and rtime < 0.5 then
                counter(akey("upstream_response_histogram_0400_to_0500", addr))
            elseif rtime > 0.5 and rtime < 0.6 then
                counter(akey("upstream_response_histogram_0500_to_0600", addr))
            elseif rtime > 0.6 and rtime < 0.7 then
                counter(akey("upstream_response_histogram_0600_to_0700", addr))
            elseif rtime > 0.7 and rtime < 0.8 then
                counter(akey("upstream_response_histogram_0700_to_0800", addr))
            elseif rtime > 0.8 and rtime < 0.9 then
                counter(akey("upstream_response_histogram_0800_to_0900", addr))
            elseif rtime > 0.9 and rtime < 1 then
                counter(akey("upstream_response_histogram_0900_to_1000", addr))
            elseif rtime > 1 and rtime < 2 then
                counter(akey("upstream_response_histogram_1000_to_2000", addr))
            elseif rtime > 2 and rtime < 3 then
                counter(akey("upstream_response_histogram_2000_to_3000", addr))
            elseif rtime > 3 and rtime < 4 then
                counter(akey("upstream_response_histogram_3000_to_4000", addr))
            elseif rtime > 4 and rtime < 5 then
                counter(akey("upstream_response_histogram_4000_to_5000", addr))
            else
                counter(akey("upstream_response_histogram_5000_to_inf", addr))
            end
        end
        if upstream_status then
            local ustatus = up_status()
            if ustatus then
                counter(akey("upstream_status_" .. ustatus, addr))
                if string.match(ustatus, "^2.*") then
                    counter(akey("upstream_status_2xx", addr))
                elseif string.match(ustatus, "^3.*") then
                    counter(akey("upstream_status_3xx", addr))
                elseif string.match(ustatus, "^4.*") then
                    counter(akey("upstream_status_4xx", addr))
                elseif string.match(ustatus, "^5.*") then
                    counter(akey("upstream_status_5xx", addr))
                end
            end
        end
        counter(key("next_upstream"))
    end

    sum(key("upstream_response_time"), total_time)
    stats:incr(key("next_upstream"), -1)
end
