local Version = require "http.version"
local HttpUtil = require "http.util"
local Zlib = require "http.zlib"
local Headers = require "http.headers"

local responseMethods = {}
local responseMetaTable = {
    __index = responseMethods;
    __name = nil;
}

local defaultServerHeader = string.format("%s/%s", Version.name, Version.version)

local errorText = [[
<html>
<head>
<title>503 Internal Server Error</title>
</head>
<body>
An internal server error occured.
</body>
</html>
]]

local function new(requestHeaders, stream)
    local headers = Headers.new();
    -- Give some defaults
    headers:append(":status", "503")
    headers:append("server", defaultServerHeader)
    headers:append("date", HttpUtil.imf_date())
    return setmetatable({
        request_headers = requestHeaders;
        stream = stream;
        -- Record peername upfront, as the client might disconnect before request is completed
        peername = select(2, stream:peername());

        headers = headers;
        body = nil;
    }, responseMetaTable)
end

function responseMethods:combinedLog()
    -- Log in "Combined Log Format"
    -- https://httpd.apache.org/docs/2.2/logs.html#combined
    return string.format('%s - - [%s] "%s %s HTTP/%g" %s %d "%s" "%s"',
        self.peername or "-",
        os.date("%d/%b/%Y:%H:%M:%S %z"),
        self.request_headers:get(":method") or "",
        self.request_headers:get(":path") or "",
        self.stream.connection.version,
        self.headers:get(":status") or "",
        self.stream.stats_sent,
        self.request_headers:get("referer") or "-",
        self.request_headers:get("user-agent") or "-")
end

function responseMethods:setStatus(status)
    self.headers:upsert(":status", status)
end

function responseMethods:setBody(body)
    self.body = body
    local length
    if type(self.body) == "string" then
        length = #body
    end
    if length then
        self.headers:upsert("content-length", string.format("%d", #body))
    end
end

function responseMethods:setAsError503()
    local headers = Headers.new()
    headers:append(":status", "503")
    headers:append("server", defaultServerHeader)
    headers:append("date", HttpUtil.imf_date())
    self.headers = headers
    headers:append("content-type", "text/html")
    self:setBody(errorText)
end

function responseMethods:enableCompression()
    if self.headers:has("content-encoding") then
        return false
    end
    local deflater = Zlib.deflate()
    local newBody = deflater(self.body, true)
    self.headers:append("content-encoding", "gzip")
    self.body = newBody
    return true
end

return  {
    new = new
}