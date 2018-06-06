local CqueuesErrno = require "cqueues.errno"
local Server = require "http.server"
local Response = require "framework.response"
local Request = require "framework.request"
local Controller = require "framework.controller"

local appMethods = {}
local appMetaTable = {
    __index = appMethods;
    __name = nil;
}

local notFoundText = [[
<html>
<head>
<title>404 Not Found</title>
</head>
<body>
It appears that the resource you are looking for is not here.
</body>
</html>
]]

local methodNotAllowedText = [[
<html>
<head>
<title>405 Method Not Allowed</title>
</head>
<body>
It appears that you are using the wrong method.
</body>
</html>
]]

local function defaultOnstream(...)
    io.stdout:write(string.format(...), "\n\n")
end

local defaultOnerror = defaultOnstream

local function defaultLog(response)
    io.stdout:write(response:combinedLog(), "\n")
end

local notFoundController = Controller.new(function(req, resp)
    resp:setStatus("404")
    resp:setBody(notFoundText)
end)

local methodNotAllowedController = Controller.new(function(req, resp)
    resp:setStatus("405")
    resp:setBody(methodNotAllowedText)
end)

function appMethods:run()
    while true do
        self.server:loop()
    end
end

local function new(options)
    local onerror = options.onerror or defaultOnerror
    local log = options.log or defaultLog
    local controllers = {};
    options.onstream = function(_, stream)
        local requestHeaders, err, errno = stream:get_headers()
        if requestHeaders == nil then
            -- connection hit EOF before headers arrived
            stream:shutdown()
            if err ~= CqueuesErrno.EPIPE and errno ~= CqueuesErrno.ECONNRESET then
                onerror("header error: %s", tostring(err))
            end
            return
        end

        local resp = Response.new(requestHeaders, stream)
        local req = Request.new(requestHeaders, stream)
        local ok, err2

        local controllersByPath = controllers[requestHeaders:get(":path")]

        if (controllersByPath) then
            local controller = controllersByPath[requestHeaders:get(":method")]

            if (controller) then
                ok, err2 = pcall(controller.performAction, controller, req, resp) -- only works in 5.2+
            else
                ok, err2 = pcall(methodNotAllowedController.performAction, methodNotAllowedController, req, resp) -- only works in 5.2+
            end
        else
            ok, err2 = pcall(notFoundController.performAction, notFoundController, req, resp) -- only works in 5.2+
        end

        log(resp)

        if stream.state ~= "closed" and stream.state ~= "half closed (local)" then
            if not ok then
                resp:setAsError503()
            end
            local isBodySent = resp.body and requestHeaders:get ":method" ~= "HEAD"
            stream:write_headers(resp.headers, not isBodySent)
            if isBodySent then
                stream:write_chunk(resp.body, true)
            end
        end
        stream:shutdown()
        if not ok then
            onerror("stream error: %s", tostring(err2))
        end
    end
    local innerServer = Server.listen(options)

    return setmetatable({
            host = options.host;
            port = options.port;
            tls = options.tls;
            server = innerServer;
            controllers = controllers;
        }, appMetaTable
    )
end

function appMethods:registerController(path, method, callback)
    if (type(callback) ~= 'function') then
        defaultOnerror("asdfasfsda")
    end

    if (self.controllers[path] == nil) then
        self.controllers[path] = {}
    end

    self.controllers[path][method] = Controller.new(callback)
end

return {
    new = new;
}