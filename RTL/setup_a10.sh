# These exports assume you have run the setup script to install the BBB code.
export FPGA_BBB_CCI_SRC=~/intel-fpga-bbb
export FPGA_BBB_CCI_INSTALL=~/intel-fpga-bbb-install

# Tool exports.
export LD_LIBRARY_PATH=/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/inteldevstack/a10_gx_pac_ias_1_2_1_pv/opencl/opencl_bsp/linux64/lib:/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/hld/host/linux64/lib:/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/hld/linux64/lib:$FPGA_BBB_CCI_INSTALL/lib64
export AOCL_BOARD_PACKAGE_ROOT=/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/inteldevstack/a10_gx_pac_ias_1_2_1_pv/opencl/opencl_bsp
export ALTERAOCLSDKROOT=/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/hld
export QUARTUS_ROOTDIR_OVERRIDE=/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/quartus
export INTELFPGAOCLSDKROOT=/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/hld
export OPAE_PLATFORM_ROOT=/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/inteldevstack/a10_gx_pac_ias_1_2_1_pv
export PATH=/glob/intel-python/python2/bin:/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/hld/bin:/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/quartus/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin:/home/u93124/.local/bin:/home/u93124/bin:/bin:/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/inteldevstack/a10_gx_pac_ias_1_2_1_pv/bin
export QUARTUS_HOME=/glob/development-tools/versions/fpgasupportstack/a10/1.2.1/intelFPGA_pro/quartus
