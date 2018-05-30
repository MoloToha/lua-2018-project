--
-- Created by IntelliJ IDEA.
-- User: antonl
-- Date: 30.05.18
-- Time: 13:31
-- To change this template use File | Settings | File Templates.
--

local ce = require "cqueues.errno"
local Headers = require "http.headers"
local Server = require "http.server"
local Version = require "http.version"
local HttpUtil = require "http.util"
--local Zlib = require "http.zlib"

local defaultServer = string.format("%s%s", Version.name, Version.version)

local helloText = [[
<html>
    <head>
        <title>Hello</title>
    </head>
    <body>
        Hello, World!
    </body>
</html>
]]

local responseMethods = {}
local responseMt = {
	__index = responseMethods;
	__name = nil;
}

local function newResponse(requestHeaders, stream)
    local headers = Headers.new()
    headers:append(":status", "200")
    headers:append("server", defaultServer)
    headers:append("date", HttpUtil.imf_date())
    headers:append("content-length", tostring(#helloText))

    return setmetatable({
        requestHeaders = requestHeaders,
        stream = stream,
        peername = select(2, stream:peername()),
        headers = headers,
        body = helloText
    }, responseMt)
end

function responseMethods:combinedLog()
    -- Log in "Combined Log Format"
    -- https://httpd.apache.org/docs/2.2/logs.html#combined
    return string.format('%s - - [%s] "%s %s HTTP/%g" %s %d "%s" "%s"',
        self.peername or "-",
        os.date("%d/%b/%Y:%H:%M:%S %z"),
        self.requestHeaders:get(":method") or "",
        self.requestHeaders:get(":path") or "",
        self.stream.connection.version,
        self.headers:get(":status") or "",
        self.stream.stats_sent,
        self.requestHeaders:get("referer") or "-",
        self.requestHeaders:get("user-agent") or "-")
end

local function replyOK(server, stream)
    local reqHeaders, err, errno = stream:get_headers()
    if reqHeaders == nil then
        -- connection hit EOF before headers arrived
        stream:shutdown()
        if err ~= ce.EPIPE and errno ~= ce.ECONNRESET then
            io.stderr.write("header error: %s", tostring(err))
        end
        return
    end
    local response = newResponse(reqHeaders, stream);

    stream:write_headers(response.headers, false)
    stream:write_chunk(response.body, true)
    stream:shutdown()

    print(response:combinedLog())
end

local serverOptions = {
    host = 'localhost',
    port = 8080,
    onstream = replyOK,
    tls = false
}

server = Server.listen(serverOptions)
print(string.format("Listening on %s:%d...", serverOptions.host, serverOptions.port))

while true do
    server:loop()
end