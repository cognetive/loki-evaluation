#!/bin/bash
sudo yum install s3fs-fuse

### mounts against minio
echo minio:minio-password > passwd-s3fs-minio
chmod 0600 passwd-s3fs-minio

mkdir -p /mnt/location
sudo umount /mnt/location
s3fs minio-app /mnt/location -o use_path_request_style -o url=https://cluster-endpoint -o passwd_file=passwd-s3fs-minio -o no_check_certificate

mkdir -p /mnt/loki
sudo umount /mnt/loki
s3fs minio-loki /mnt/loki -o use_path_request_style -o url=https://cluster-endpoint -o passwd_file=passwd-s3fs-minio -o no_check_certificate


### mounts against COS
echo cos-key:cos-password > passwd-s3fs-cos
chmod 0600 passwd-s3fs-cos

mkdir -p /mnt/cos-location
sudo umount /mnt/cos-location
s3fs cos-app /mnt/cos-location -o use_path_request_style -o url=https://cos-endpoint -o passwd_file=passwd-s3fs-cos -o no_check_certificate

mkdir -p /mnt/cos-loki
sudo umount /mnt/cos-loki
s3fs cos-loki /mnt/cos-loki -o use_path_request_style -o url=https://cos-endpoint -o passwd_file=passwd-s3fs-cos -o no_check_certificate

mount | grep fuse.s3fs
