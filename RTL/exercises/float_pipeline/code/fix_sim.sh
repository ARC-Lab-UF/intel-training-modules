if [ $# -ne 1 ]
then
    echo "Usage: $0 sim_dir"
    echo "sim_dir: simulation directory created by afu_sim_setup"
    exit 1
fi

if [ ! -d "$1" ]
then
    echo "Directory $1 does not exist."
    exit 1
fi

if [ ! -f "$1/ase_sources.mk" ]
then
    echo "Warning: Destination directory $1 does not appear to have been created by afu_sim_setup"    
fi

cp custom_sim/* $1
sed -i.bak '/+incdir+/d' $1/vhdl_files.list

