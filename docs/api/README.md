# Arynox OS API Reference

## D-Bus Interfaces

All system services communicate via D-Bus. Below is the complete API reference.

### System Services

| Interface | Bus | Path | Description |
|-----------|-----|------|-------------|
| `org.arynox.Session` | session | `/org/arynox/Session` | Session lifecycle management |
| `org.arynox.Compositor` | session | `/org/arynox/Compositor` | Window manager control |
| `org.arynox.Compositor.Window` | session | `/org/arynox/Compositor/Window` | Per-window operations |
| `org.arynox.Compositor.Workspace` | session | `/org/arynox/Compositor/Workspace` | Virtual desktop management |
| `org.arynox.Compositor.Output` | session | `/org/arynox/Compositor/Output` | Display configuration |
| `org.arynox.Shell` | session | `/org/arynox/Shell` | Desktop shell state |
| `org.arynox.Notifications` | session | `/org/arynox/Notifications` | Notification system |
| `org.arynox.AiRuntime` | session | `/org/arynox/AiRuntime` | AI inference engine |
| `org.arynox.DeviceManager` | system | `/org/arynox/DeviceManager` | Hardware detection |
| `org.arynox.NetworkManager` | system | `/org/arynox/NetworkManager` | Network configuration |
| `org.arynox.PackageManager` | system | `/org/arynox/PackageManager` | Package management |
| `org.arynox.Security` | system | `/org/arynox/Security` | Security & permissions |
| `org.arynox.Cloud` | session | `/org/arynox/Cloud` | Cloud sync services |
| `org.arynox.DevTools` | session | `/org/arynox/DevTools` | Developer tools |
| `org.arynox.Updates` | system | `/org/arynox/Updates` | OTA update system |
| `org.arynox.Installer` | system | `/org/arynox/Installer` | System installer |
| `org.arynox.Recovery` | system | `/org/arynox/Recovery` | Recovery environment |

### AI Runtime HTTP API

The AI Runtime also exposes an HTTP REST API on `127.0.0.1:8741`:

```http
POST /v1/chat
Content-Type: application/json

{
  "provider": "groq",
  "model": "llama3-70b-8192",
  "messages": [{"role": "user", "content": "Hello"}],
  "stream": false
}
```

```http
GET /v1/providers
→ [{"name": "groq", "online": true, "model": "llama3-70b-8192"}, ...]
```

```http
GET /v1/health
→ {"status": "ok"}
```

## Error Codes

| Code | Meaning |
|------|---------|
| `E_PERMISSION_DENIED` | User denied the permission request |
| `E_NOT_FOUND` | Resource not found |
| `E_ALREADY_EXISTS` | Resource already exists |
| `E_INVALID_ARGUMENT` | Invalid parameters |
| `E_INTERNAL` | Internal service error |
| `E_NETWORK` | Network connectivity error |
| `E_AUTH_FAILED` | Authentication failed |
| `E_ENCRYPTION` | Encryption/decryption error |
