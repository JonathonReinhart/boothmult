#!/bin/bash
################################################################################
##   ____  ____
##  /   /\/   /
## /___/  \  /    Vendor: Xilinx
## \   \   \/     Version : 1.05
##  \   \         Application : ICON v1.05_a Core
##  /   /         Filename : implement_sh.ejava 
## /___/   /\     
## \   \  /  \
##  \___\/\___\
##
##
## implement.sh script 
## Generated by Xilinx ICON v1.05_a Core
##
#-----------------------------------------------------------------------------
# Script to synthesize and implement the RTL provided for the ICON core
#-----------------------------------------------------------------------------
#Exit on Error enabled.
set -o errexit

#Create results directory
rm -rf results
mkdir results
echo 'Running Coregen on VIO required for example design'
coregen -b chipscope_vio.xco -p coregen.cgp
# Check Results
if [ $? -gt 0 ] ; then 
echo An error occurred running coregen on chipscope_vio
echo FAIL
exit
fi

##-------------------------------Run Xst on Example design----------------------------
echo 'Running Xst on example design'
xst -ifn example_chipscope_icon.xst -ofn example_core.log -intstyle silent
# Check Results
if [ $? -gt 0 ] ; then 
echo An error occurred running XST on example_chipscope_icon
echo FAIL
exit
fi
cp chipscope_vio.ngc ./results
cp ../../chipscope_icon.ngc        ./results
cp example_chipscope_icon.ngc        ./results
cd ./results
##-------------------------------Run ngdbuild---------------------------------------
echo 'Running ngdbuild'
ngdbuild -uc ../../example_design/example_chipscope_icon.ucf -p xc5vfx70t-ff1136-1 -sd . example_chipscope_icon.ngc example_chipscope_icon.ngd
if [ $? -gt 0 ] ; then 
echo An error occurred running NGDBUILD on example_chipscope_icon 
echo FAIL
exit
fi
#end run ngdbuild section
##-------------------------------Run map-------------------------------------------
echo 'Running map'
map -w -p xc5vfx70t-ff1136-1 -o example_chipscope_icon.map.ncd example_chipscope_icon.ngd
if [ $? -gt 0 ] ; then 
echo An error occurred running MAP on example_chipscope_icon 
echo FAIL
exit
fi
##-------------------------------Run par-------------------------------------------
echo 'Running par'
par -w -ol high example_chipscope_icon.map.ncd example_chipscope_icon.ncd 
if [ $? -gt 0 ] ; then 
echo An error occurred running PAR on example_chipscope_icon 
echo FAIL
exit
fi
##---------------------------Report par results-------------------------------------
echo 'Running design through bitgen'
bitgen -d -g GWE_cycle:Done -g GTS_cycle:Done -g DriveDone:Yes -g StartupClk:Cclk -w example_chipscope_icon.ncd
if [ $? -gt 0 ] ; then 
echo An error occurred running BITGEN on example_chipscope_icon 
echo FAIL
exit
else
echo PASS
exit
fi
