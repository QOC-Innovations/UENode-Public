#!/bin/bash

# Reset "Runtime" directory
if [ -d $HOME/Runtime ]; then
    sudo rm -r $HOME/Runtime
fi
mkdir -p $HOME/Runtime/tarball
TARBALL_DIR="$HOME/Runtime/tarball"
DEST_DIR="$HOME/Runtime/NodeFiles"
mkdir -p $HOME/Runtime/NodeFiles/Vulkan

# Move tar files to tarball directory
cp *.tar.gz $HOME/Runtime/tarball/

# Extract files
tar -xvzf $TARBALL_DIR/node_scripts.tar.gz -C $DEST_DIR
tar -xvzf $TARBALL_DIR/node_gpio.tar.gz -C $DEST_DIR
tar -xvzf $TARBALL_DIR/node_orbit.tar.gz -C $DEST_DIR
tar -xvzf $TARBALL_DIR/node_os_support.tar.gz -C $DEST_DIR
tar -xvzf $TARBALL_DIR/node_UE5Node.tar.gz -C  $DEST_DIR
tar -xvzf $TARBALL_DIR/node_vulkan1.tar.gz --strip-components=1 -C $DEST_DIR/Vulkan
tar -xvzf $TARBALL_DIR/node_vulkan2.tar.gz --strip-components=1 -C $DEST_DIR/Vulkan
EXTRACT_DIR="$DEST_DIR/UE5Node/Content/Paks"
if [ ! -d "$EXTRACT_DIR" ]; then
    mkdir -p "$EXTRACT_DIR"
fi
for tarball in "$TARBALL_DIR"/pakchunk0.part*.tar.gz; do
  tar -xvzf "$tarball" -C "$EXTRACT_DIR"
done

# Recombine pak files
cd $DEST_DIR/UE5Node/Content/Paks
PREFIX="pakchunk0.part"
OUTPUT="pakchunk0-LinuxArm64.pak"
cat ${PREFIX}* > "$OUTPUT"

chmod 700 $HOME/Runtime/NodeFiles/InstallationScripts/reset.sh

