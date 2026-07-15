# Arynox OS Release Checklist

## Pre-Release

### Code Quality
- [ ] All CI checks pass (build, test, lint, analyze)
- [ ] No `TODO`, `FIXME`, `HACK`, or `XXX` in production code
- [ ] All unsafe Rust code reviewed
- [ ] All API keys references removed from code
- [ ] CHANGELOG updated

### Security
- [ ] Security audit completed
- [ ] All API keys encrypted at rest
- [ ] Secure Boot keys provisioned
- [ ] TPM measured boot verified
- [ ] AppArmor/SELinux policies written
- [ ] Firewall rules tested

### Performance
- [ ] Boot time < 10s (measured on reference hardware)
- [ ] RAM idle < 1GB
- [ ] CPU idle < 2%
- [ ] GPU compositing at 60fps
- [ ] AI inference latency < 500ms (cloud), < 2s (local)

### Hardware Compatibility
- [ ] x86_64 desktop (Intel/AMD)
- [ ] ARM64 (Raspberry Pi 5)
- [ ] Touchscreen tablet
- [ ] Multi-monitor
- [ ] HiDPI display
- [ ] USB boot
- [ ] NVMe SSD
- [ ] SATA SSD/HDD

### Features
- [ ] Desktop shell boots and is responsive
- [ ] Window manager: tiling, snap, virtual desktops
- [ ] AI Assistant: text conversation works
- [ ] AI Copilot: context actions work
- [ ] AI Runtime: all providers connect
- [ ] File Manager: browse, search, tabs
- [ ] Device Manager: hotplug detection
- [ ] Software Center: install/remove/list
- [ ] Settings: all pages functional
- [ ] Network: WiFi connect, Bluetooth
- [ ] OTA Updates: check, download, apply
- [ ] Installer: full installation flow
- [ ] Recovery: snapshot restore, factory reset

## Release Process

1. [ ] Create release branch: `release/vMAJOR.MINOR.PATCH`
2. [ ] Update version numbers across all Cargo.toml and pubspec.yaml
3. [ ] Run full test suite
4. [ ] Build installer ISO
5. [ ] Test clean install on reference hardware
6. [ ] Test upgrade from previous version
7. [ ] Sign release artifacts (GPG)
8. [ ] Tag release: `git tag -s vMAJOR.MINOR.PATCH`
9. [ ] Create GitHub Release with changelog
10. [ ] Publish installer ISO to download server
11. [ ] Update update server with new version manifest
12. [ ] Post-release: bump version to next dev cycle

## Version Template

```
ARYNOX_OS_VERSION="0.1.0"
ARYNOX_OS_CODENAME="Alpha"
KERNEL_VERSION="6.6.30"
BUILD_DATE="$(date -u +%Y-%m-%d)"
```
