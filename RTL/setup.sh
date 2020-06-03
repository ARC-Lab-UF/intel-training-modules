REPO_PATH=~/intel-fpga-bbb
INSTALL_PATH=~/

if [ ! -d "$REPO_PATH" ]
then
    git clone https://github.com/OPAE/intel-fpga-bbb $REPO_PATH
fi

(cd $REPO_PATH; git checkout release/1.3.0; mkdir mybuild)
(cd $REPO_PATH/mybuild; cmake ..)
(cd $REPO_PATH/mybuild; make)
(cd $REPO_PATH/mybuild; make install DESTDIR=$INSTALL_PATH)




