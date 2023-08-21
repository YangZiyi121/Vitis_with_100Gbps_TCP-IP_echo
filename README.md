<h2>Echo workload for Alveo with Vitis 100Gbps TCP Networking</h2>

This project provides a baseline for abstract overhead measurement using a 100Gbps network. It is achieved by expanding the [100Gbps TCP/IP stack repository](https://github.com/fpgasystems/Vitis_with_100Gbps_TCP-IP) with a custom user kernel.


<h3>Functionality</h3>

The kernel will echo back the last dataline (512-bit) of the packet. 

<h3>How to invoke</h3>

Please send a packet which has a content size multiples of 512-bit (64-byte)

```python

#3 * 512-bit packet
0000000800000002000000030000000400000006000000060000000300000008000000090000000a0000000b0000000c0000000d0000000e0000001f0000002e
01000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000010000000100000001000000
0000000900000002000000030000000400000006000000060000000300000008000000090000000a0000000b0000000c0000000d0000000e0000001f0000002e

```


<h3>Build and Run</h3>

**Clone the Repository**

```
git clone	
```

**Configure TCP Stack**

```
mkdir build
cd build
cmake .. -DFDEV_NAME=u280 -DTCP_STACK_EN=1 -DTCP_STACK_RX_DDR_BYPASS_EN=1 
make installip
```

**Create Design**
```
cd ../
make all TARGET=hw DEVICE=/opt/xilinx/platforms/xilinx_u280_xdma_201920_3/xilinx_u280_xdma_201920_3.xpfm USER_KRNL=top_k_krnl USER_KRNL_MODE=rtl NETH=4
```

<h3>Power profile</h3>

1. After compilation, copy **xrt.ini** under the folder that contains the .xclbin file (build_dir.hw.xilinx_u280_xdma_201920_3)
2. Run the host code using cmd

  ```
./host/host build_dir.hw.xilinx_u280_xdma_201920_3/network.xclbin
  ```
3. Open the project with vitis_analyzer, the report will be shown
   
**Reference**

[Profile document](https://docs.xilinx.com/r/en-US/ug1393-vitis-application-acceleration/Enabling-Profiling-in-Your-Application)

[Visualisation result](https://xilinx.github.io/xbtest/doc/main/user-guide/build/html/docs/usage/result-visualisation.html)
