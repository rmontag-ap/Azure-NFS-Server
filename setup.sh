#!/bin/bash
# parameter 1 = name for new resource group
# parameter 2 = location
# it will create a Storage Account with the same name as the group
# parameter 3 = ImageURL
# parameter 4 = Image Key

/usr/bin/azure group create $1 $2
/usr/bin/azure storage account create -g $1 -l $2 --type LRS $1

destkey=`/usr/bin/azure storage account keys list -g $1 $1 | grep Primary | cut -f 3 -d ':'`

/usr/bin/azure storage container create -a $1 -k $destkey vhds

# pip install blobxfer

sa_domain=$(echo "$3" | cut -f3 -d/)
sa_name=$(echo $sa_domain | cut -f1 -d.)
container_name=$(echo "$3" | cut -f4 -d/)

blob_name=$(echo "$3" | cut -f5 -d/)

echo ""
echo "sa name, container name, blob name:"
echo $sa_name
echo $container_name
echo $blob_name

blobxfer $sa_name $container_name /mnt/resource/ --remoteresource $blob_name --storageaccountkey $4 --download --no-computefilemd5

blobxfer $1 vhds "/mnt/resource/$blob_name" --storageaccountkey $destkey --upload --no-computefilemd5 --autovhd --no-recursive

/usr/bin/azure group deployment create $1 deploy1 -f 'New Cluster pubaddr.json' -p '{ "newStorageAccount": { "value": "'$1'" }}'

exit

