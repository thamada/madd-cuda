//Time-stamp: <2013-11-28 11:35:34 hamada>
// FMA performance metor by Tsuyoshi Hamada

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <assert.h>

//#define REAL float
#define REAL double

#define DEVICE_ID (0)

#define NUM_MP (15)  // MultiProcessor (G92-GTS = 16, GT280 = 30)
#define NUM_SP_PER_BLOCK (192)
#define NUM_THREADS_PER_BLOCK (NUM_SP_PER_BLOCK*5)
#define NUM_BLOCKS (NUM_MP * 16)
#define NUM_ITERATIONS (1<<10)


/*
#define NUM_MP (16)
#define NUM_THREADS_PER_SM (384)
#define NUM_THREADS_PER_BLOCK (192)
#define NUM_BLOCKS ((NUM_THREADS_PER_SM / NUM_THREADS_PER_BLOCK) * NUM_MP)
#define NUM_ITERATIONS 30
*/

/*
#define NUM_MP (30)  // MultiProcessor (G92-GTS = 16, GT280 = 30)
#define NUM_THREADS_PER_BLOCK (128)
#define NUM_THREADS_PER_SM (128*16)
#define NUM_BLOCKS ((NUM_THREADS_PER_SM / NUM_THREADS_PER_BLOCK) * NUM_MP)
#define NUM_ITERATIONS (2048)
*/

/*
#define NUM_MP (30)  // MultiProcessor (G92-GTS = 16, GT280 = 30)
#define NUM_THREADS_PER_BLOCK (128)
#define NUM_THREADS_PER_SM (128*16)
#define NUM_BLOCKS ((NUM_THREADS_PER_SM / NUM_THREADS_PER_BLOCK) * NUM_MP)
#define NUM_ITERATIONS (2048)
*/


// 128 MAD instructions
#define FMAD128(a, b) \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \
  a *= b * a + b; \
  b *= a * b + a; \


__shared__ REAL result[NUM_THREADS_PER_BLOCK];


__device__ void fma128x16(REAL& a, REAL& b)
{
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
    FMAD128(a, b);
}

__global__ void gpu_func()
{
  REAL a = result[threadIdx.x];  // this ensures the mads don't get compiled out
  REAL b = 1.01f;

  for(int i=0; i<NUM_ITERATIONS; i++){
    fma128x16(a, b); // 1
    fma128x16(a, b); // 2
    fma128x16(a, b); // 3
    fma128x16(a, b); // 4
    fma128x16(a, b); // 5
    fma128x16(a, b); // 6
    fma128x16(a, b); // 7
    fma128x16(a, b); // 8
    fma128x16(a, b); // 9
  }
  /*
  fma128x16(a, b); // 10
  fma128x16(a, b); // 11
  fma128x16(a, b); // 12
  fma128x16(a, b); // 13
  fma128x16(a, b); // 14
  fma128x16(a, b); // 15
  fma128x16(a, b); // 16
  */
  result[threadIdx.x] = a + b;
}

#include <sys/time.h> 
#include <sys/resource.h>

double get_time(void)
{
  static struct timeval tv;
  static struct timezone tz;
  gettimeofday(&tv, &tz);
  return ((double)(tv.tv_sec  + tv.tv_usec*1.0e-6)); 
}


int run(int devid) 
{
	int n_dev = -1;
  cudaGetDeviceCount(&n_dev);
	assert(0 < n_dev);
	printf("# of devices: %d\n", n_dev);

	// set Device ID as Round-robin
	devid = devid % n_dev;

	cudaSetDevice(devid);
	cudaGetDevice(&devid);
	printf("devid: %d\n", devid);
	cudaDeviceProp deviceProp;
	cudaGetDeviceProperties(&deviceProp, devid);
	printf("[%d]: Device PCI Bus ID / PCI location ID: %x / %x\n",
				 devid, deviceProp.pciBusID, deviceProp.pciDeviceID);
	cudaThreadSynchronize();

  // execute kernel
  double time = get_time();
  gpu_func<<<NUM_BLOCKS, NUM_THREADS_PER_BLOCK>>>();

  cudaThreadSynchronize();
  time = get_time() - time;

  // output results
  printf( "[%d]: Time: %f (ms)\n", devid, time*1000.0);
  const double num_fma = 16. * 9. * (double)NUM_ITERATIONS;
  const double flop = (double)(64. * 3. * num_fma) * (double)(NUM_BLOCKS * NUM_THREADS_PER_BLOCK);
  const double flops = flop/time;
	//  printf("[%d]: flop: %e\n", devid, flop);
  printf("[%d]: Gflops: %f\n", devid, flops / 1.0e+9 );
	printf("\n");
  return (0);
}

int main(int argc, char** argv) 
{
	int devid = DEVICE_ID;
	printf("N_BLOCK: %d\n", NUM_BLOCKS);
	printf("N_THREAD: %d\n", NUM_THREADS_PER_BLOCK);

	if(argc > 1){
		devid = atoi(argv[1]);
		run(devid);
	}else{
		for(devid = 0; devid < 16; devid++)	run(devid);
	}
	return 0;
}
