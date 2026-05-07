#!/bin/sh
set -eu

curl -fsSL https://www.scottishferryapp.com/openapi.json \
  -o FerryServices_2/openapi.json

curl -fsSL https://www.scottishferryapp.com/api/services \
  | jq 'map(.additional_info = null | .disruption_reason = null | .last_updated_date = null | .status = -99 | .updated = "1970-01-01T00:00:00Z" | .vessels = [] | .locations |= map(del(.weather, .next_departure, .next_rail_departure, .scheduled_departures)))' \
  > FerryServices_2/services.json
