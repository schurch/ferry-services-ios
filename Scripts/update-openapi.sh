#!/bin/sh
set -eu

curl -fsSL https://www.scottishferryapp.com/openapi.json \
  -o FerryServices_2/openapi.json

curl -fsSL https://www.scottishferryapp.com/api/offline/snapshot.json \
  -o FerryServices_2/offline-snapshot.json
