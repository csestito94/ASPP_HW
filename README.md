# A SoC implementation of Atrous Spatial Pyramid Pooling for Fully Convolutional Networks

**Team number**: xohw19-188.

**Project name**: A SoC implementation of Atrous Spatial Pyramid Pooling for Fully Convolutional Networks.

**Date**: June 27, 2019.

**Version of uploaded archive**: 1.

**University name**: University of Calabria - Department of Informatics, Modeling, Electronics and System Engineering.

**Supervisor name**: Stefania Perri.

**Supervisor e-mail**: stefania.perri@unical.it.

**Participant**: Cristian Sestito.

**Email**: cristian.sestito@gmail.com.


**Board used**: Digilent ZedBoard Zynq-7000 ARM/FPGA SoC Development Board.

**Vivado Version**: 2017.4.

**Brief description of project:**

This design provides a novel IP Core which adopts the Atrous Spatial Pyramid Pooling approach to better perform Semantic Image Segmentation for Deep Learning purposes. By applying dilated convolutions at different rates, researchers have shown that this strategy allows a better management of fields-of-view and the ability to better recognize objects at several scales.
By exploiting the parallelization ability of FPGAs, several dilated convolutions and a Global Average Pooling are performed jointly. 
By using a ZedBoard, the whole system allows the communication between the core and the DDR, through DMAs; the tests aim to verify the correct execution of the operations, through a comparison between the results provided by the component and stored in the DDR and the results provided by a MATLAB script which emulates its behaviour.


**Description of archive:**

- doc\ : 

	 -> .\xohw_19_188_project_report.pdf.

	 -> .\BMG_settings.txt: refers to the Block Memory Generator IP settings.

	 -> .\DMAs_settings.txt: refers to the AXI Direct Memory Access IP settings.
	
- hw\ : contains the final bitstream.

- ip\ : contains the Atrous Spatial Pyramid Pooling IP Core sources.

	.\The_Atrous_Spatial_Pyramid_Pooling\src : contains all the VHDL design codes, including a testbench and the clock constraint.

	 -> .\blk_mem_gen_0: Block Memory Generator IP Core files.
	
	 -> .\accum_pool.vhd: accumulator for the Global Average Pooling.
	
	 -> .\adder_param.vhd: parameterized adder.

	 -> .\array_def.vhd: custom types & constants valid for the whole IP.

	 -> .\ASPP_net_top.vhd: the Atrous Spatial Pyramid Pooling top module (w/o AXI Full Interface).

	 -> .\ASPP_tb.vhd: example testbench.

	 -> .\Atrous_Spatial_Pyramid_Pooling_v1_0.vhd: top module (ASPP_net_top + AXI Full Interface).

	 -> .\Atrous_Spatial_Pyramid_Pooling_v1_0_S00_AXI.vhd: AXI Full interface (provided by Xilinx and adapted properly).

	 -> .\buffer_atrous_param.vhd: parameterized Zero-Padding & Dilated Windows component.

	 -> .\buffer_win_param.vhd: parameterized Convolution Window (conv win).

	 -> .\control_unit.vhd: IP Moore Finite State Machine (FSM).

	 -> .\ctrl_weights.vhd: coefficient unit FSM.

	 -> .\fmaps_accum.vhd: fmap homologous values accumulator.

	 -> .\gap.fsm.vhd: Global Average Pooling FSM.

	 -> .\global_average_pooling.vhd: Global Average Pooling top module.

	 -> .\line_buffer_param.vhd: parameterized FIFO (for conv win).

	 -> .\MAC_module.vhd: 3x3 convolution top module.

	 -> .\mult_param.vhd: parameterized multiplier.

	 -> .\multiplexer_2to1_param.vhd: parameterized 2to1 mux.

	 -> .\multiplexer_2to1_sel2bit_param.vhd: parameterized 2to1 mux with 2bit selector (for ReLU activation).

	 -> .\parallel_MAC_param.vhd: provides parallel MAC modules.

	 -> .\parallel_ReLU_param.vhd: provides parallel ReLU modules.

	 -> .\reg_param.vhd: parameterized n bit register.

	 -> .\ReLU_compute.vhd: ReLU top module.

	 -> .\row_win_param.vhd: parameterized SIPO register (each conv win row).

	 -> .\sel_decoder_param.vhd: Zero-Padding mux decoder.

	 -> .\up_counter_limited_param.vhd: up counter for Zero-Padding.

	 -> .\weights_array.vhd: parameterized SIPO register (for coefficient storing).

	 -> .\weights_unit.vhd: coefficient unit top module.

	 -> .\constr_clk.xdc: 100MHz clock constraint.
		
- MATLAB\: 

	 -> .\ASPP.m performs the Atrous Spatial Pyramid Pooling by software.
	
	 -> .\GAP.m performs the Global Average Pooling by software.
	
	 -> .\ifmap_gen.m provides ifmaps by writing values in text files.
	
	 -> .\write_files_header.m provides ifmaps.h in order to being copied into SDK directory.
	
	 -> .\ifmapx.txt(.h) contains ifmap values.
	
	 -> .\hw_results.txt contains addresses & ofmap data stored into DDR.
	
	 -> .\hw_res_final.txt contains ofmap data only.
	
- sw\ : contains the final executable software routine.

- ASPP_BlockDesign.xpr.zip : contains the complete ready-to-use VIVADO project.

- project_ASPP.xpr.zip : contains the only ready-to-use VIVADO Atrous Spatial Pyramid Pooling IP project.

	Relevant files:
	
	-> .\project_ASPP\project_ASPP.sim\sim_1\impl\timing\xsim\res.log: post impl time sim outputs.
	
	-> .\project_ASPP\project_ASPP.sim\sim_1\impl\timing\xsim\impl_time.saif: SAIF file for Power Estimation.


**Instructions to build and test project:**

Step 1: Decompress the ASPP_BlockDesign.xpr.zip archive and open the project by using VIVADO.

Step 2: Generate all the IP Core Output Products.

Step 3: Run Synthesis,Implementation & Bistream Generation.

Step 4: Export HW results into SDK and launch it.

Step 5: Program FPGA, open the Serial COM Port and run the configuration. Check that ifmapx.h files are in \ASPP_BlockDesign\ASPP_BlockDesign.sdk\ASPP_sw\src directory.

Step 6: Write the results, stored into the DDR, in a text file through the XSCT prompt by using these lines:

-> set logfile [open "your_MATLAB_directory\hw_results.txt" "w"]
	
-> puts $logfile [mrd DDR_Dest_BaseAddr no_32bit_words] 
(where DDR_Dest_BaseAddr is the address associated to the 1st ofmap value, and no_32bit_word refers to the fmap area (200*200 = 40k in this case)).
	
-> close $logfile
	
Step 7: Open the text file and delete the address column (in this case, the final file is "hw_res_final.txt"). Hence, open the ASPP.m in MATLAB and run it. In the command window, "Correct results" will be printed to. Global Average Pooling results are printed to the serial window; you could verify their correct value by running the GAP.m.

According to the report section "Design reuse", the VHDL codes are highly parameterizable. Therefore, you could modify them to generate a different Atrous Spatial Pyramid Pooling (e.g. by using ifmap with different sizes, or by using a lower rate_array dimension). Mind that you have to generate BRAM banks according to your changes, by using the Block Memory Generator IP Core properly.
This design processes a 200x200x3 ifmap tensor. You could process 200x200xDEPTH ifmap tensor (generated by using the ifmap_gen.m & write_files_header.m), by modifying the software routine properly.


**Link to YouTube Video:** https://youtu.be/csjqzAHQjns
