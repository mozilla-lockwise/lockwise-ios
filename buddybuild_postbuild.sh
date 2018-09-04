#!/usr/bin/env bash
if [ "$BUDDYBUILD_SCHEME" = "lockbox" ]; then
  bash <(curl -s https://codecov.io/bash) -J Lockbox -t $CODECOV_TOKEN
fi
