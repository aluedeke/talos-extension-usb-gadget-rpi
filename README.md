# USB Gadget Ethernet Extension for Raspberry Pi 4

Talos Linux system extension that enables USB gadget mode on Raspberry Pi 4,
allowing network connectivity and power delivery over a single USB-C cable.

**Auto-starts at boot** - no manual intervention required!

## Requirements

- **Hardware**: Raspberry Pi 4 (Pi 5 USB-C is power-only and won't work)
- **Talos**: v1.6.0+

## Build

### Automated (GitHub Actions)

The image is automatically built and pushed to `ghcr.io` on:
- Push to `main` branch → `ghcr.io/<owner>/usb-gadget-rpi:latest`
- Git tags (`v*`) → `ghcr.io/<owner>/usb-gadget-rpi:v1.0.0`

To release a new version:
```bash
git tag v0.1.0
git push origin v0.1.0
```

### Manual Build

```bash
# Build for arm64 (RPi4)
docker buildx build --platform linux/arm64 -t ghcr.io/<owner>/usb-gadget-rpi:v0.1.0 --push .

# Local testing
docker build -t usb-gadget-rpi:test .
```

## Create Talos Image

### Using Talos Imager CLI

```bash
docker run --rm -v $(pwd):/out \
  ghcr.io/siderolabs/imager:v1.11.5 \
  metal --arch arm64 \
  --system-extension-image ghcr.io/qawolf/usb-gadget-rpi:v0.1.0
```

### Using Image Factory

1. Go to https://factory.talos.dev/
2. Select Talos version and `metal` platform
3. Select `arm64` architecture
4. Add custom extension image URL
5. Download the generated image

## Talos Machine Configuration

Add to your `controlplane.yaml` or `worker.yaml`:

```yaml
machine:
  install:
    extensions:
      - image: ghcr.io/qawolf/usb-gadget-rpi:v0.1.0
    extraKernelArgs:
      - dwc2.dr_mode=peripheral

  kernel:
    modules:
      - name: dwc2

  network:
    interfaces:
      - interface: usb0
        addresses:
          - 10.55.0.1/24
        routes:
          - network: 0.0.0.0/0
            gateway: 10.55.0.2
```

## Usage

The extension service `ext-usb-gadget` starts automatically at boot and
configures the USB gadget. The `usb0` interface will be available for
Talos to configure.

### On the Host Computer

**Linux:**
```bash
sudo ip addr add 10.55.0.2/24 dev usb0
sudo ip link set usb0 up

# Enable NAT for internet access to the Pi
sudo iptables -t nat -A POSTROUTING -s 10.55.0.0/24 -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1
```

**macOS:**
The device appears as "RNDIS/Ethernet Gadget" in System Preferences > Network.
Configure with IP 10.55.0.2, subnet 255.255.255.0.

### Verify Connectivity
```bash
ping 10.55.0.1
ssh root@10.55.0.1  # Or use talosctl
```

## Service Management

```bash
# Check service status
talosctl -n <ip> service ext-usb-gadget

# View logs
talosctl -n <ip> logs ext-usb-gadget

# Restart service
talosctl -n <ip> service ext-usb-gadget restart
```

## Troubleshooting

### No UDC Found (Service Fails)

Ensure `dwc2.dr_mode=peripheral` is in kernel args:
```bash
talosctl -n <ip> read /proc/cmdline | grep dwc2
```

### usb0 Interface Not Created

Check service logs:
```bash
talosctl -n <ip> logs ext-usb-gadget
```

Check kernel messages:
```bash
talosctl -n <ip> dmesg | grep -i gadget
```

### Host Doesn't See Device

- Ensure USB-C cable supports data (not power-only)
- Try different USB port on host
- Check host `dmesg` for USB enumeration

## How It Works

This extension includes a Talos extension service that runs at boot:

1. The `ext-usb-gadget` service starts after machine configuration
2. Mounts configfs and creates USB gadget via `/sys/kernel/config`
3. Configures CDC ECM function which creates the `usb0` interface
4. Binds to the DWC2 UDC (USB Device Controller)

The Pi then appears as a USB Ethernet adapter to the connected host.

## Extension Structure

```
/rootfs/
├── usr/local/etc/containers/
│   └── usb-gadget.yaml          # Service definition
└── usr/local/lib/containers/
    └── usb-gadget/              # Service container rootfs
        ├── bin/
        │   ├── busybox
        │   └── sh -> busybox
        └── usb-gadget-init.sh   # Init script
```

## References

- [Linux USB Gadget ConfigFS](https://docs.kernel.org/usb/gadget_configfs.html)
- [Talos Extension Services](https://www.talos.dev/v1.9/advanced/extension-services/)
- [Talos System Extensions](https://www.talos.dev/v1.11/talos-guides/configuration/system-extensions/)
