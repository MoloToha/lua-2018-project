# Project description
A small microframework for Web development which supports simple routing, template rendering and other minor things like logging, session handling, etc.

# Project phases
- **Phase 1**: research available instruments. We need at least: HTTP library, existing HTML template language for Lua. Prepare a little prototype using found instruments. Decide on framework's project structure
- **Phase 2**: Partially implement `http_app` module with methods for registering controllers for given routes
    1) Implement server which listens on given host and port, optionally with TLS. It should use custom cqueue, catch all errors and log them (currently on stderr), handle simultaneous requests. Wrap this server in `http_app` module so that user can require it and run on given host and port. This also means implementation of infrastructure, e.g. request and response containers.
    2) Implement possibility to add user-defined custom callback to app from outside the module, which has 1 argument: request and returns response (without routing, e.g. `app.registerController(actionCallback)`).
    3) Implement possibility to resolve path for which given callback should be executed thus enabling multiple controllers. Also add possibility to register controllers for different methods (e.g. `app.registerController("/hello", "GET", getHello); app.registerController("/hello", "POST", postHello)`).
    4) Consider safety, e.g. registering two controllers which may conflict with each other (meaning that a request exists, for which app cannot choose which controller to use).
    
- **Phase 3**: finish routing, implement template rendering
    1) Implement possibility to check route against a pattern to enable passing arguments to callbacks in route, e.g. `app.registerController("/user/{id}", "GET", getUserById)`. Consider optional arguments, argument type check.
    2) Implement shortcuts for registering controllers for at least `GET`, `POST`, `PUT`, `DELETE` HTTP methods, e.g. `app.get("/hello/{id}", getUserById)`.
    3) Implement `http.app.template` which is a wrapper for lua-resty-template allowing for same functionality
    4) Implement aliases for templates, allowing rendering by alias.
    5) Implement quick way to reference other implemented pages, e.g. `<a href="{{ url_for('auth.logout') }}">Log Out</a>` (like in Flask)
- **Phase 4**: implement remaining elements: logging, session handling
    1) Implement logging module which should be able to choose where to output, set verbosity, use different log levels (trace, debug, info, notice, warning, error, EMERGENCY)
    2) Implement simple session handling via customizable session cookie. Implement simple storage interface so that user can choose how to store session data hinself. Implement default handler which uses files.

# Chosen instruments:
- HTTP library: https://github.com/daurnimator/lua-http
- HTML template language: https://github.com/bungle/lua-resty-template
