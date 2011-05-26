#!/bin/sh

PORT=9090
plackup -Ilib -p $PORT bin/app.psgi

