#!/bin/bash
# start.sh - 경고 메시지 필터링
npm start 2>&1 | grep -v "DEP_WEBPACK_DEV_SERVER"