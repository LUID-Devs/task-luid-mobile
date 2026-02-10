# TaskLuid iOS (SwiftUI)

SwiftUI mobile client for TaskLuid, modeled after the architecture and design system used in `language-luid-ios`.

## Structure

- `Source/Core` - app configuration, networking, auth, storage
- `Source/Core/DesignSystem` - reusable UI primitives
- `Source/Models` - API data models
- `Source/Services` - API services per domain
- `Source/ViewModels` - observable view models
- `Source/Views` - SwiftUI screens

## API Base URL

Update `Source/Core/Config/AppConfig.swift` with your backend URL.

```
#if targetEnvironment(simulator)
http://127.0.0.1:8000
#else
http://<YOUR_MAC_IP>:8000
#endif
```

The backend uses Cognito tokens. The app sends `Authorization: Bearer <accessToken>` and `X-ID-Token` headers when available.

## Xcode Project

Open `task-luid-ios/TaskLuid/TaskLuid.xcodeproj` in Xcode.

## Next Steps

- Set the bundle identifier and app icon in Xcode if needed.
- Run the backend (`task-luid-backend`) locally.
# task-luid-mobile
