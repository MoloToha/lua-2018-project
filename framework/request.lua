local requestMethods = {}

local requestMetaTable = {
    __index = requestMethods;
    __name = nil;
}

local timeout = 2

local function new(requestHeaders, stream)
    return setmetatable({
        headers = requestHeaders;
        body = stream:get_body_as_string(timeout);
    }, requestMetaTable)
end

return {
    new = new
}