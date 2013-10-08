#!/bin/bash

# Adapted from http://dan.carley.co/blog/2012/04/17/centos-amis-from-kickstart/
# NOTE: Currently only tested in Scientific Linux (i.e. won't work on apt-based systems)

# TODO: parameterize:
#   - AMI name
#   - working directory
#   - base OS
#   - kickstart config file
#   - EC2 region

##############################

# First, copy EC2 x.509 certificate and pk to ~/ec2/certificates

# put the following in ~/.bashrc, fill out appropriately, and source:
#export EC2_HOME=~/ec2/tools
#export EC2_PRIVATE_KEY=~/ec2/certificates/<your-pk>.pem
#export EC2_CERT=/home/vagrant/ec2/certificates/<your-cert>.pem
#export EC2_URL=https://ec2.us-west-2.amazonaws.com
#export AWS_ACCOUNT_NUMBER=<your-AWS-account-number>
#export AWS_ACCESS_KEY_ID=<access-key>
#export AWS_SECRET_ACCESS_KEY=<access-secret>
#export AWS_AMI_BUCKET=<AMI-bucket>
#export PATH=$PATH:$EC2_HOME/bin
#export JAVA_HOME=/usr

# Run the following to find the kernel image to use, and pick the one with the desired architecture:
# Note that hd0 kernels are for instance-store images, and hd00 kernels are for EBS-backed
# ec2-describe-images --owner amazon --region us-west-2 | grep "amazon\/pv-grub-hd00"
##############################

AMI_NAME=ScientificLinux-6.4-x86_64-raw
KERNEL_ID=aki-f837bac8

# mkdir -p ~/ec2/{tools,certificates,images,yum,mnt,repos}
# 
# # Install prerequisites
# sudo yum update
# sudo yum install epel-release java-1.6.0-openjdk unzip python-imgcreate
# 
# # Download and install EC2 Command Line Tools
# curl -o /tmp/ec2-api-tools.zip http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
# curl -o /tmp/ec2-ami-tools.zip http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip
# unzip /tmp/ec2-api-tools.zip -d /tmp
# unzip /tmp/ec2-ami-tools.zip -d /tmp
# cp -r /tmp/ec2-api-tools-*/* ~/ec2/tools/
# cp -r /tmp/ec2-ami-tools-*/* ~/ec2/tools/
# 
# # Create a local image of the OS
# ./ami_creator/ami_creator.py -n ${AMI_NAME} -c ks-ScientificLinux64.cfg

# Make an EBS volume to copy the image to
# ec2-create-volume -z us-west-2a -s 8

# Attach the volume
# TODO: capture the output of the volume creation and get the current instance id for use here
VOLUME_ID=vol-204bf449
INSTANCE_ID=i-fe049dc9
# ec2-attach-volume ${VOLUME_ID} -i ${INSTANCE_ID} -d /dev/sdi

# Make the device bootable
# TODO: get the proper device id for use here
DEVICE_ID=xvdm
# sfdisk /dev/${DEVICE_ID} << EOF
# 0,,83,*
# ;
# ;
# ;
# EOF

# Copy the image to the EBS partition, clean it, and resize
# dd if=${AMI_NAME}.img of=/dev/${DEVICE_ID}1 bs=8M
# e2fsck -f /dev/${DEVICE_ID}1
# resize2fs /dev/${DEVICE_ID}1
# sync

# Create an EBS snapshot
# ec2-create-snapshot -d ${AMI_NAME} ${VOLUME_ID}
SNAPSHOT_ID=snap-f2ec6fc8
ec2-register --block-device-mapping /dev/sda=${SNAPSHOT_ID}::true --name "${AMI_NAME} EBS-Backed" --description "${AMI_NAME} EBS Backed" --architecture x86_64 --kernel ${KERNEL_ID}

#TODO: delete the volume and snapshot?
