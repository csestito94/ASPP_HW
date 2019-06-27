/******************************************************************************
*
* The Atrous Spatial Pyramid Pooling Neural Network
* C script
* Designer: Cristian Sestito
*
******************************************************************************/

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "ifmap1.h"
#include "ifmap2.h"
#include "ifmap3.h"

#define FMAP_SIZE 			200
#define WEIGHT_SIZE 		9
#define DDRCoeffAddr 		0x00100000 + 0x27100
#define DDRSourceAddr_map1 	0x01000000
#define DDRSourceAddr_map2 	0x01100000
#define DDRSourceAddr_map3 	0x01200000
#define DDRDestAddr   		0x01300000
#define BTT_coeff     		0x24 // 3*3*4
#define BTT_map       		0x27100 // 200*200*4
#define DDRconv1 	  		0x01400000

int main()
{
    init_platform();

    /* Cache disabling (HP ports aren't cache coherent) */
    Xil_DCacheDisable();

    /* Platform test */
    xil_printf("The Atrous Spatial Pyramid Pooling Test\n\r");

    /*************************************************************************
     ****************************INPUT DATA STORING***************************
     ************************************************************************/

    /* Weight array inizialization */
    signed char coeff[9] = {-128,0,64,-32,-1,127,-16,8,4};

    /* Writing weights into DDR */
    xil_printf ("Writing weights into DDR\n");
    for (u32 i = 0; i <= WEIGHT_SIZE-1; i++) {
    	Xil_Out32(DDRCoeffAddr + 4*i, coeff[i]);
    };
    xil_printf("Weights written into DDR\n\r");

    /* Writing ifmap tensor into DDR */
    xil_printf ("Writing 200*200*3 ifmap tensor into DDR\n");
    for (u32 i = 0; i <= FMAP_SIZE*FMAP_SIZE-1; i++) {
    	Xil_Out32(DDRSourceAddr_map1 + 4*i, ifmap1[i]);
    	Xil_Out32(DDRSourceAddr_map2 + 4*i, ifmap2[i]);
    	Xil_Out32(DDRSourceAddr_map3 + 4*i, ifmap3[i]);
    };
    xil_printf("ifmap tensor written into DDR\n\r");

    /*************************************************************************
     ***********ASPP IP CORE INIZIALIZATION & WEIGHTS TRANSMISSION************
     ************************************************************************/

    /* Starting ASPP Control Unit */
    xil_printf("Starting ASPP Control Unit\n");
    Xil_Out32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR,0x1);
    Xil_Out32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR,0x0);
    u32 ASPP_Stat_Reg;
    ASPP_Stat_Reg = Xil_In32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR);
    xil_printf("ASPP_Stat_Reg = %x\n\r",ASPP_Stat_Reg);

    /* DMA1 : MM2S channel configuration */
    xil_printf("Preparing DMA1 and sending weights to the ASPP IP Core\n");
    Xil_Out32(XPAR_AXI_DMA_1_BASEADDR + 0x0, 0x4); // assert reset
    Xil_Out32(XPAR_AXI_DMA_1_BASEADDR + 0x0, 0x0); // deassert reset
    Xil_Out32(XPAR_AXI_DMA_1_BASEADDR + 0x0, 0x1); // start MM2S Channel
    Xil_Out32(XPAR_AXI_DMA_1_BASEADDR + 0x18, DDRCoeffAddr); // Weights SourceAddr
    Xil_Out32(XPAR_AXI_DMA_1_BASEADDR + 0x28, BTT_coeff); // ByteToTransfer

    /* DMA1 Polling */
    u32 Status,StatusReg;
    Status = StatusReg & 0x1002;
    while(Status != 0x1002) {
    	StatusReg = Xil_In32(XPAR_AXI_DMA_1_BASEADDR + 0x4);
    	Status = StatusReg & 0x1002;
    };

    xil_printf("Weights transfer completed\n\r");

    /*************************************************************************
     **********************1st 200*200 IFMAP TRANSMISSION*********************
     ************************************************************************/

    /* DMA0 : MM2S channel configuration */
    xil_printf("Preparing DMA0 and sending 1st ifmap to the ASPP IP Core\n");
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x0, 0x4); // assert reset
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x0, 0x0); // deassert reset
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x0, 0x1); // start MM2S Channel
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x18, DDRSourceAddr_map1); // SourceAddr
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x28, BTT_map); // ByteToTransfer

    /* Polling */
    Status = StatusReg & 0x1002;
    while(Status != 0x1002) {
    	StatusReg = Xil_In32(XPAR_AXI_DMA_0_BASEADDR + 0x4);
    	Status = StatusReg & 0x1002;
    };

    xil_printf("1st ifmap transfer completed\n\r");

    /*************************************************************************
     *******************1st GLOBAL AVERAGE POOLING RESULT*********************
     ************************************************************************/

    xil_printf("1st GAP reading\n");
    /* Reading from ASPP IP Core */
    u32 avg_val;
    avg_val = Xil_In32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR + 0x4);
    xil_printf("avgpool = %d\n\r",avg_val);
    /* Storing into DDR */
    xil_printf("1st GAP storing into DDR\n");
    Xil_Out32(0x10000000, avg_val);
    u32 avg1=Xil_In32(0x10000000);
    xil_printf("Reading 1st GAP from DDR: %d\n\r",avg1);

    /*************************************************************************
     **********************2nd 200*200 IFMAP TRANSMISSION*********************
     ************************************************************************/

    /* DMA0 : MM2S channel configuration */
    xil_printf("Sending 2nd ifmap to the ASPP IP Core\n");
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x18, DDRSourceAddr_map2); // SourceAddr
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x28, BTT_map); // ByteToTransfer

    /* Polling */
    Status = StatusReg & 0x1002;
    while(Status != 0x1002) {
    	StatusReg = Xil_In32(XPAR_AXI_DMA_0_BASEADDR + 0x4);
    	Status = StatusReg & 0x1002;
    };

    xil_printf("2nd ifmap transfer completed\n\r");

    /*************************************************************************
     *******************2nd GLOBAL AVERAGE POOLING RESULT*********************
     ************************************************************************/

    xil_printf("2nd GAP reading\n");
    /* Reading from ASPP IP Core */
    avg_val = Xil_In32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR + 0x4);
    xil_printf("avgpool = %d\n\r",avg_val);
    /* Storing into DDR */
    xil_printf("2nd GAP storing into DDR\n");
    Xil_Out32(0x10000000+0x4, avg_val);
    u32 avg2=Xil_In32(0x10000000+0x4);
    xil_printf("Reading 2nd GAP from DDR: %d\n\r",avg2);

    /*************************************************************************
     ****************ReLU ACTIVATION & DMA0 S2MM INIZIALIZATION***************
     ************************************************************************/

    /* ReLU enabling */
    xil_printf("ReLU enabling\n");
    Xil_Out32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR,0x2); // ReLU enable
    ASPP_Stat_Reg = Xil_In32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR);
    xil_printf("ASPP_Stat_Reg = %x\n\r",ASPP_Stat_Reg);

    /* DMA0 : S2MM channel configuration */
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x30, 0x1); // start Channel
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x48, DDRDestAddr); // DestAddr
    Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x58, BTT_map); // ByteToTranfer

    /*************************************************************************
     **********************3rd 200*200 IFMAP TRANSMISSION*********************
     ************************************************************************/

    /* DMA0 : MM2S channel configuration */
	xil_printf("Sending 3rd ifmap to the ASPP IP Core\n");
	Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x18, DDRSourceAddr_map3); // SourceAddr
	Xil_Out32(XPAR_AXI_DMA_0_BASEADDR + 0x28, BTT_map); // ByteToTransfer

    /* Polling */
    Status = StatusReg & 0x1002;
    while(Status != 0x1002) {
    	StatusReg = Xil_In32(XPAR_AXI_DMA_0_BASEADDR + 0x4);
    	Status = StatusReg & 0x1002;
    };

    xil_printf("3rd ifmap transfer completed\n\r");

    /* Polling */
    Status = StatusReg & 0x1002;
    while(Status != 0x1002) {
    	StatusReg = Xil_In32(XPAR_AXI_DMA_0_BASEADDR + 0x34);
    	Status = StatusReg & 0x1002;
    };

    xil_printf("ofmap transfer completed\n\r");

    /*************************************************************************
     *******************3rd GLOBAL AVERAGE POOLING RESULT*********************
     ************************************************************************/

    xil_printf("3rd GAP reading\n");
    /* Reading from ASPP IP Core */
    avg_val = Xil_In32(XPAR_ATROUS_SPATIAL_PYRAMID_POOLING_V1_0_0_BASEADDR + 0x4);
    xil_printf("avgpool = %d\n\r",avg_val);
    /* Storing into DDR */
    xil_printf("3rd GAP storing into DDR\n");
    Xil_Out32(0x10000000+0x8, avg_val);
    u32 avg3=Xil_In32(0x10000000+0x8);
    xil_printf("Reading 3rd GAP from DDR: %d\n\r",avg3);

    /* Reading transfered data into DDR
     * Format : filt_pix_rate6 - filt_pix_rate12 - filt_pix_rate18 - filt_pix_rate24
     */
    //xil_printf("Reading filtered frame...\n");
    //u32 rofmap;
    //for (u32 i = 39990; i <= 39999; i++) {
    //	rofmap = Xil_In32(DDRDestAddr + 4*i);
    //	xil_printf("Addr %d: %x\n", i, DDRDestAddr + 4*i);
    //	xil_printf("Data %d: %x\n\r", i, rofmap);
    //}

    /*************************************************************************
     ****************************1x1 CONVOLUTION******************************
     ************************************************************************/

    /* Weight array inizialization */
    signed char wconv1[3] = {-10,5,20};
    xil_printf("Executing 1x1 Convolution...\n");
    s32 wsum = 0;
    for (u32 i = 0; i <= 2; i++) {
    	wsum = wsum + wconv1[i];
    }

    s32 conv1res;
    for(u32 i = 0; i<= FMAP_SIZE*FMAP_SIZE-1; i++) {
    	conv1res=ifmap1[i]*wsum;
    	Xil_Out32(DDRconv1 +4*i, conv1res);
    }
    xil_printf("1x1 Convolution ended...\n");

    //xil_printf("Reading conv1x1 results...\n");
    //u32 rofconv1;
    //for (u32 i = 0; i <= 9; i++) {
    //	rofconv1 = Xil_In32(DDRconv1 + 4*i);
    //	xil_printf("Addr %d: %x\n", i, DDRconv1 + 4*i);
    //	xil_printf("Data %d: %d\n\r", i, rofconv1);
    //}

    cleanup_platform();
    return 0;
}
