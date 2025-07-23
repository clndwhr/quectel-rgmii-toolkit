#!/bin/sh

newroot() {
    /bin/echo "Begin mount fix process to make a usable userspace for OpenWRT Subsystem"

    # Forcefully unmount /etc
    /bin/echo "Unmounting the bind at /etc"
    /bin/umount -lf /etc

    # Remount root filesystem as read-write
    /bin/echo "Remounting / as read-write"
    /bin/mount -o remount,rw /
    
    # Make mount namespaces private
    mount --make-rprivate /

    # Ensure necessary directories exist for overlay and pivot_root
    /bin/echo "Creating new overlay system"
    if [ ! -d /usrdata/rootfs ]; then
        mkdir -p /usrdata/rootfs
    fi
    if [ ! -d /usrdata/rootfs-workdir ]; then
        mkdir -p /usrdata/rootfs-workdir
    fi
    if [ ! -d /rootfs ]; then
        mkdir -p /rootfs
    fi

    # Mount the new overlay filesystem
    /bin/mount -t overlay overlay -o lowerdir=/,upperdir=/usrdata/rootfs,workdir=/usrdata/rootfs-workdir /rootfs

    # Create the real_rootfs directory in the new root
    if [ ! -d /rootfs/real_rootfs ]; then
        mkdir -p /rootfs/real_rootfs
    fi

    # Pivot root to the new root
    /bin/echo "Pivoting Root / to /rootfs; Be back soon!!"
    /sbin/pivot_root /rootfs /rootfs/real_rootfs >/dev/null 2>&1

    # Move the mounted filesystems to the new locations
    /bin/echo "Moving previous mount points to the new root"
    /bin/mount --move /real_rootfs/sys /sys
    /bin/mount --move /real_rootfs/proc /proc
    /bin/mount --move /real_rootfs/tmp /tmp
    /bin/mount --move /real_rootfs/dev /dev
    /bin/mount --move /real_rootfs/firmware /firmware
    /bin/mount --move /real_rootfs/usrdata /usrdata
    /bin/mount --move /real_rootfs/persist /persist
    /bin/mount --move /real_rootfs/cache /cache
    /bin/mount --move /real_rootfs/data /data
    /bin/mount --move /real_rootfs/run /run
    /bin/mount --move /real_rootfs/etc/machine-id /etc/machine-id
    /bin/mount --move /real_rootfs/var/volatile /var/volatile
    /bin/mount --move /real_rootfs/systemrw /systemrw
    
    # Bind-mount core mountpoints back into real_rootfs for chroot/debug
    /bin/echo "Binding previous mount points to the old root"
    /bin/mount --bind /dev /real_rootfs/dev
    /bin/mount --bind /proc /real_rootfs/proc
    /bin/mount --bind /sys /real_rootfs/sys
    /bin/mount --bind /tmp /real_rootfs/tmp
    /bin/mount --bind /run /real_rootfs/run
    /bin/mount --bind /firmware /real_rootfs/firmware
    /bin/mount --bind /persist /real_rootfs/persist
    /bin/mount --bind /cache /real_rootfs/cache
    /bin/mount --bind /data /real_rootfs/data
    /bin/mount --bind /systemrw /real_rootfs/systemrw
    /bin/mount --bind /usrdata /real_rootfs/usrdata
    /bin/mount --bind /etc /real_rootfs/etc
    /bin/mount --bind /etc/machine-id /real_rootfs/etc/machine-id
    /bin/mount --bind /var/volatile /real_rootfs/var/volatile
    
    # Mount orginal rootfs as RO
    /bin/mount -o remount,ro /real_rootfs
    
    echo "Complete"
}

newroot

