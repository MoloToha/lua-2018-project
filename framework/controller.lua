local controllerMethods = {}

local controllerMetaTable = {
    __index = controllerMethods;
    __name = nil;
}

function controllerMethods:performAction(req, resp)
    self.action(req, resp)
end

local function new(action)
    return setmetatable({
        action = action;
    }, controllerMetaTable)
end

return {
    new = new
}