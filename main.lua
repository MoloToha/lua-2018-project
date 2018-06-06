local port = arg[1] or "8000"

local App = require "framework.app"

local function actionCallback(req, resp)

    resp:setStatus("200")
    resp:setBody("12345")

end

local function postActionCallback(req, resp)

    resp:setStatus("200")
    resp:setBody(req.body)

end

local app = assert(App.new {
    host = "localhost";
    port = port;
})

app:registerController("/kek", "GET", actionCallback)
app:registerController("/kek", "POST", postActionCallback)

app:run()