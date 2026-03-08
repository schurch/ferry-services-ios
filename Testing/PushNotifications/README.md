# Push Notification Test Payloads

Use these payloads with `simctl push`:

```bash
xcrun simctl push booted com.stefanchurch.ferryservices Testing/PushNotifications/service-status.apns
xcrun simctl push booted com.stefanchurch.ferryservices Testing/PushNotifications/text-alert.apns
```

Because these files include `Simulator Target Bundle`, you can also run:

```bash
xcrun simctl push booted Testing/PushNotifications/service-status.apns
xcrun simctl push booted Testing/PushNotifications/text-alert.apns
```

Payload descriptions:

- `service-status.apns`: includes top-level `service_id` (currently `14`, a valid ID from `services.json`); should navigate to service details on tap.
- `text-alert.apns`: alert-only payload; should show alert message path in app.
