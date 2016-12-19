#Time-stamp: <2013-11-28 11:37:02 hamada>

#GPU_ARC = --gpu-name 'sm_13'
#GPU_ARC = --gpu-name 'sm_10'

all:
	nvcc main.cu -o run.x --ptxas-options=-v -Xcompiler " -Wall" \
    -arch=sm_35

#    -arch=sm_13
#    -arch=sm_30
#    -arch=sm_20 --fmad=true -use_fast_math
#     -use_fast_math


all.0:
	nvcc main.cu -o run.x \
          $(GPU_ARC) \
          -Xcompiler "-m64" \
          -Xcompiler "-fPIC " \
          -Xcompiler "-O3 " \
          -Xcompiler " " \
          -DUNIX -O3 \
          -I$(SDK_INSTALL_PATH)/common/inc \
          -I$(CUDA_INSTALL_PATH)/include \
          -I. \
          -L$(CUDA_INSTALL_PATH)/../NVIDIA_GPU_Computing_SDK/CUDALibraries/common/lib \
          -L $(SDK_INSTALL_PATH)/lib -L . -lcutil_x86_64 


ptx:
	nvcc  --ptx main.cu  -I. -I$(CUDA_INSTALL_PATH)/include -I$(SDK_INSTALL_PATH)/common/inc



cubin:
	nvcc  -cubin main.cu  -I. -I$(CUDA_INSTALL_PATH)/include -I$(SDK_INSTALL_PATH)/common/inc
	grep smem main.cubin
	grep reg main.cubin

