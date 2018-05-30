#!/usr/bin/env bash

if [ $(whoami) != 'root' ]; then
    echo "Need root privileges... Try to run this as sudo"
    exit 1;
fi

if ! [ -x "$(command -v luarocks)" ]; then
  echo 'Error: luarocks is not installed.' >&2
  exit 1
fi

echo "Installing dependencies..."

LUA_DEPS=(http lua-resty-template)

echo "Installing Lua dependencies..."

for lua_dep in ${LUA_DEPS[@]}; do
    echo "Installing ${lua_dep}..."
    luarocks install ${lua_dep}
    echo "Done installing ${lua_dep}."
done

echo "Done installing Lua dependencies."

echo "Done installing dependencies."

exit 0