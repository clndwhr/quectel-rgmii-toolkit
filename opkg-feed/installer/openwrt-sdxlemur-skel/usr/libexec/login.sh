#!/bin/sh

[ "$(uci -q get system.@system[0].ttylogin)" = 1 ] || exec env LOGIN_TIMEOUT=300 /bin/login