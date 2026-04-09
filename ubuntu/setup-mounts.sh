mkdir -p /mnt/nfs/raid1-bigc
mkdir -p /mnt/nfs/raid1-camelot
mkdir -p /mnt/nfs/SAMSUNG

sudo mount -v -o rw,async m910q:/media/xcvb/raid1-camelot /mnt/nfs/raid1-camelot
sudo mount -v -o rw,async m910q:/media/xcvb/raid1-bigc /mnt/nfs/raid1-bigc
sudo mount -v -o rw,async m910q:/media/xcvb/SAMSUNG /mnt/nfs/SAMSUNG
