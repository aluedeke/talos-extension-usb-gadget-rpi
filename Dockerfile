# Build the service container with busybox
FROM alpine:3.20 AS builder

# Install busybox statically
RUN apk add --no-cache busybox-static

# Create container rootfs structure
RUN mkdir -p /container-rootfs/bin /container-rootfs/sys

# Copy busybox as sh
RUN cp /bin/busybox.static /container-rootfs/bin/busybox && \
    ln -s busybox /container-rootfs/bin/sh && \
    ln -s busybox /container-rootfs/bin/ls && \
    ln -s busybox /container-rootfs/bin/mkdir && \
    ln -s busybox /container-rootfs/bin/echo && \
    ln -s busybox /container-rootfs/bin/cat && \
    ln -s busybox /container-rootfs/bin/ln && \
    ln -s busybox /container-rootfs/bin/mount && \
    ln -s busybox /container-rootfs/bin/mountpoint && \
    ln -s busybox /container-rootfs/bin/head && \
    ln -s busybox /container-rootfs/bin/cd

# Copy the init script
COPY rootfs/usr/local/lib/containers/usb-gadget/usb-gadget-init.sh /container-rootfs/usb-gadget-init.sh
RUN chmod +x /container-rootfs/usb-gadget-init.sh

# Build the extension image
FROM scratch

# Extension manifest
COPY manifest.yaml /

# Service definition
COPY rootfs/usr/local/etc/containers/usb-gadget.yaml /rootfs/usr/local/etc/containers/usb-gadget.yaml

# Service container rootfs
COPY --from=builder /container-rootfs/ /rootfs/usr/local/lib/containers/usb-gadget/
