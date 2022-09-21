#!/bin/sh

REPO_PATH=~/intel-fpga-bbb
INSTALL_PATH=~/intel-fpga-bbb-install

if [ -d "$REPO_PATH" ]
then
    echo "Target folder $REPO_PATH already exists."
    read -n 1 -p "Would you like to remove it to continue setup? (y/n) " input
    echo ""
    case $input in  
        y|Y) 
            echo "Removing old folder."
            rm -rf $REPO_PATH ;;
        *)
            echo "Exiting."
            exit 1 ;; 
    esac
fi

# Clone the BBB repository into $REPO_PATH
git clone https://github.com/OPAE/intel-fpga-bbb $REPO_PATH

# Checkout a specific release of the repository and make the build directory
(cd $REPO_PATH; git checkout release/1.3.0; mkdir mybuild)
# (cd $REPO_PATH; git checkout a422c8498ce7c3267ce287530317c5d4903d6845; mkdir mybuild)


# Make and install the BBB modules to $INSTALL_PATH
(cd $REPO_PATH/mybuild; cmake -DCMAKE_INSTALL_LIBDIR=lib64 -DCMAKE_INSTALL_PREFIX=$INSTALL_PATH ..)
(cd $REPO_PATH/mybuild; make -j)
(cd $REPO_PATH/mybuild; make install)
