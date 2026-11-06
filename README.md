# Linux 6.12 Tiny Kernel & Bootable ISO Builder

Automated GitHub Actions builder for a lightweight Linux 6.12 kernel tailored for QEMU emulation with modern desktop and diagnostic capabilities.

## Features

- **Kernel Version**: Linux 6.12.10 (Tiny-XFCE profile)
- **DRM Panic Subsystem**:
  - `CONFIG_DRM_PANIC=y`
  - `CONFIG_DRM_PANIC_SCREEN_QR_CODE=y` (Generates scannable QR code on kernel crash)
  - `CONFIG_DRM_PANIC_SCREEN_USER=y` (User-friendly panic screen formatter)
- **Display & Graphics**:
  - Bochs DRM (`CONFIG_DRM_BOCHS=y`) for standard QEMU VGA (`-vga std`)
  - SimpleDRM & EFI Framebuffer (`CONFIG_DRM_SIMPLEDRM=y`, `CONFIG_FB_EFI=y`)
- **Sound**:
  - Intel HDA Audio (`CONFIG_SND_HDA_INTEL=y`)
  - AC97 / Intel8x0 legacy support
- **Desktop & Browser Support**:
  - All namespaces (`USER_NS`, `PID_NS`, `NET_NS`) and cgroups required for Chromium / QtWebEngine / Falkon sandboxing
  - Seccomp BPF filter, memfd, futex, epoll
- **Bootable Artifacts**:
  - Hybrid UEFI + BIOS `linux.iso` created with GRUB
  - Standalone `bzImage` kernel binary

## How to Build

1. Push this repository to GitHub or click **Actions** -> **Build Linux 6.12 Kernel & Bootable ISO** -> **Run workflow**.
2. GitHub Actions runs the automated workflow defined in [.github/workflows/build.yml](.github/workflows/build.yml).
3. Download the built `bzImage` and `linux.iso` from the **Artifacts** section.

## How to Run in QEMU

Run the provided launcher:
```cmd
run.bat
```
This automatically starts QEMU with hardware acceleration, Bochs graphics, Intel HDA sound, and network connectivity.
