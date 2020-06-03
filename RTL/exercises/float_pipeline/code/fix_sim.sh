#!/bin/sh

# Check proper usage
if [ $# -ne 1 ]
then
    echo "Usage: $0 sim_dir"
    echo "sim_dir: simulation directory created by afu_sim_setup"
    exit 1
fi

# Make sure the selected directory exists
if [ ! -d "$1" ]
then
    echo "Directory $1 does not exist."
    exit 1
fi

# See if the directory looks like it was created by afu_sim_setup
if [ ! -f "$1/ase_sources.mk" ]
then
    echo "Warning: Destination directory $1 does not appear to have been created by afu_sim_setup"    
fi

# Copy the custom simulation files over the default ones
cp custom_sim/* $1

# Older versions of afu_sim_setup add the +incdir+ sources to the 
# vhdl_files.list, which causes syntax error during make.
# This simply removes the corresponding lines from that file.
sed -i.bak '/+incdir+/d' $1/vhdl_files.list

