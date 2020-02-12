#!/bin/bash

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# We do not want users to end up with a partially working install, so we exit the script
# instead of continuing the installation with something broken
set -e


HWMODEL="NanoPiNEO2-ARMv8"

GITREPO="https://github.com/jerryhopper/swph.git"
GITBRANCH="$HWMODEL"



cd $HWMODEL





is_command() {
    # Checks for existence of string passed in as only function argument.
    # Exit value of 0 when exists, 1 if not exists. Value is the result
    # of the `command` shell built-in call.
    local check_command="$1"

    command -v "${check_command}" >/dev/null 2>&1
}

try_unmount(){
    # -----
    local unmount_command="$1"
    sudo umount $unmount_command
}

if is_command 7z; then
   echo  "Preparing..."
else  # bash
   echo  "the 7z command doesnt exist!"
   exit
fi

FNAME="DietPi_$HWMODEL-Buster"
ZIPFILENAME="$FNAME.7z"
FILENAME="$FNAME.img"

ROOTPATH="$PWD"
MOUNTPATH="$ROOTPATH/mountpoint"
GITPATH="$ROOTPATH/git"
GITFILE="$GITPATH/README.md"
ODST="$ROOTPATH/original"
FILE="$ROOTPATH/original/$FILENAME"



# Check if repo is initialized and pull repo.
if [ -d $GITPATH ]; then
    echo "Local repo exists."
    cd $GITPATH
    sudo git status
    sudo git remote update
    sudo git status
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(sudo git rev-parse @)
    REMOTE=$(sudo git rev-parse "$UPSTREAM")
    BASE=$(sudo git merge-base @ "$UPSTREAM")
    COMMIT_ID=$(sudo git rev-parse --verify HEAD)
    if [ $LOCAL = $REMOTE ]; then
        echo "Up-to-date"
        exit 1
    elif [ $LOCAL = $BASE ]; then
        echo "Need to pull"
        git pull
    elif [ $REMOTE = $BASE ]; then
        echo "Need to push"
        exit 1
    else
        echo "Diverged"
        exit 1
    fi
    cd ..
else
    echo "Cloning repo" 
    sudo git clone $GITREPO $GITPATH -b $GITBRANCH 
    COMMIT_ID=$(sudo git rev-parse --verify HEAD)
fi

    




# Check if a image is mounted.
if [ -d "$MOUNTPATH/etc" ]; then
    try_unmount $MOUNTPATH
else
    echo "not mounted."     
fi


# Unpack the original image.
cd original
7z -y e $ZIPFILENAME -o$ODST
cd ..



echo "Mounting image..."

BOOTSTARTSTR=$(sudo fdisk  -l $FILE|grep ".img1"|cut -d' ' -f 8)
FILESYSTEMSTR=$(sudo fdisk -l $FILE|grep ".img1"|cut -d' ' -f 14)
SECSTARTSTR=$(sudo fdisk -l $FILE|grep -m 2 "Sector size"|cut -d' ' -f 4)
BOOTSTART=$((BOOTSTARTSTR * SECSTARTSTR))


sudo mount -o loop,rw,sync,offset=$BOOTSTART $FILE $MOUNTPATH

echo "mount $MOUNTPATH"


echo "Copy files to mounted image..."
cp -r $GITPATH/etc $MOUNTPATH
cp -r $GITPATH/boot $MOUNTPATH
cp $GITPATH/README.md $MOUNTPATH/README.md
echo COMMIT_ID> $MOUNTPATH/boot/commit_id

echo "Unmounting..."
sudo umount $MOUNTPATH

echo "Creating archive: $HWMODEL.7z"
7z a "$HWMODEL.7z" $FILE>/dev/null


rm -f $FILE
echo "done!"
