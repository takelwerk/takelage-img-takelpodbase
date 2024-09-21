#!/bin/bash

apt-get -y update
apt-get -y dist-upgrade
apt-get install -y --no-install-recommends python3 python3-apt sudo systemd
apt-get --yes --no-install-recommends install \
  ca-certificates \
  libvshadow-utils \
  passt \
  podman \
  podman-compose \
  python3-minimal \
  python3-apt \
  slirp4netns \
  sudo \
  systemd \
  uidmap
apt-get clean
rm -fr /sbin/initctl
cat > /sbin/initctl <<sbin_initctl
#!/bin/sh
ALIAS_CMD="\$(echo ""\$0"" | sed -e 's?/sbin/??')"
case "\$ALIAS_CMD" in
    start|stop|restart|reload|status)
        exec service \$1 \$ALIAS_CMD
        ;;
esac
case "\$1" in
    list )
        exec service --status-all
        ;;
    reload-configuration )
        exec service \$2 restart
        ;;
    start|stop|restart|reload|status)
        exec service \$2 \$1
        ;;
    \?)
        exit 0
        ;;
esac
sbin_initctl
chmod +x /sbin/initctl
/usr/sbin/useradd \
  --comment 'podman user to run rootless containers' \
  --home-dir /home/podman \
  --create-home \
  --shell /bin/bash \
  --user-group \
  podman
su podman -c 'mkdir -p /home/podman/.config/containers'
su podman -c 'echo -e "[storage]\ndriver = \"vfs\"\n" > /home/podman/.config/containers/storage.conf'
echo -e "[storage]\ndriver = \"vfs\"\n" > /etc/containers/storage.conf
mkdir -p  /var/run/containers/storage
mkdir -p /var/lib/containers
cat > /etc/containers/storage.conf <<storage_conf
[storage]
driver = "vfs"
runroot = "/var/run/containers/storage"
graphroot = "/var/lib/containers"
storage_conf
