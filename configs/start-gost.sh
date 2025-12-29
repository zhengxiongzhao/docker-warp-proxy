#!/bin/bash
exec gost -L tcp://:$PROXY_PORT/127.0.0.1:40000 -L udp://:$PROXY_PORT/127.0.0.1:40000