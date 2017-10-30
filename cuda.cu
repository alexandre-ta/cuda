#include <stdio.h>
#include "cuda.h"
#include "cuda_runtime.h"
// Define matrix width
#define N 100
#define BLOCK_DIM 32
#define SIGMA 20.0
// Define tile size
#define TILE_WIDTH 2

// Non shared version
__global__ void computeMatrix(float *dVectorA, float *dVectorB, float *dVectorC, int length, float sigma)
{
    int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;
	int tid = length * y + x;
	float tmp = 0;

    if (x < length && y < length)
	{
        tmp = dVectorA[tid] - dVectorB[tid];
		tmp = (tmp*tmp)/(2*(sigma*sigma));
		dVectorC[tid] = exp(-tmp);
	}
}

// Shared version doesn't work
__global__ void computeMatrixShared(float *dVectorA, float *dVectorB, float *dVectorC, int length, float sigma)
{
	__shared__ float Ads[TILE_WIDTH][TILE_WIDTH];
	__shared__ float Bds[TILE_WIDTH][TILE_WIDTH];

	float tmp = 0;
	unsigned int col = TILE_WIDTH*blockIdx.x + threadIdx.x;
	unsigned int row = TILE_WIDTH*blockIdx.y + threadIdx.y;
	
	for(int m = 0; m < length/TILE_WIDTH; m++)
	{
		Ads[threadIdx.y][threadIdx.x] = dVectorA[row * length +(m * TILE_WIDTH + threadIdx.x)];
		Bds[threadIdx.y][threadIdx.x] = dVectorB[(m*TILE_WIDTH + threadIdx.y) * length + col];
		// Synchronize all threads
		__syncthreads();
		for(int k = 0; k < TILE_WIDTH; k++)
		{
			tmp = Ads[threadIdx.x][k] + Bds[k][threadIdx.y];
			tmp = (tmp*tmp)/(2*(sigma*sigma));
			dVectorC[row * length +  col] = exp(-tmp);
		}

		// Synchronize all threads
		__syncthreads();
	}
}

int main()
{
    cudaSetDevice(0);

	int totalLength = N * N;
    float hVectorA[totalLength];
    float hVectorB[totalLength];
    float hVectorC[totalLength];
    float *dVectorA = NULL;
    float *dVectorB = NULL; 
    float *dVectorC = NULL; 
	// Fill arrays
    for (int i = 0; i < totalLength; i++)
    {
        hVectorA[i] = 2*i;
        hVectorB[i] = 1*i;
    }
	int size = sizeof(float) * totalLength;
	// Transfert A and B to device
    cudaMalloc((void**) &dVectorA, size);
    cudaMalloc((void**) &dVectorB, size);
    cudaMalloc((void**) &dVectorC, size);
    cudaMemcpy(dVectorA, hVectorA, size, cudaMemcpyHostToDevice);
    cudaMemcpy(dVectorB, hVectorB, size, cudaMemcpyHostToDevice);

	// -- Non shared version
	// -- Grid mapping
    dim3 blocks((totalLength + BLOCK_DIM - 1) / BLOCK_DIM);
    dim3 threads(BLOCK_DIM);

	// -- Kernel invocation code
    computeMatrix<<<blocks, threads>>>(dVectorA, dVectorB, dVectorC, N, SIGMA);

	// -- Shared version
	// -- Grid mapping
    //dim3 dimGrid ( N/TILE_WIDTH , N/TILE_WIDTH ,1 ) ;
	//dim3 dimBlock( TILE_WIDTH, TILE_WIDTH, 1 ) ;

	// -- Kernel invocation code
    //computeMatrixShared<<<dimGrid, dimBlock>>>(dVectorA, dVectorB, dVectorC, N, (float)SIGMA);

	// Transfert C from device to host
    cudaMemcpy(hVectorC, dVectorC, size, cudaMemcpyDeviceToHost);

    for (int i = 0; i < totalLength; i++)
        printf("%0.1f\t", hVectorC[i]);
    printf("\n");
	
	// Free memories
	cudaFree(dVectorA);
	cudaFree(dVectorB);
	cudaFree(dVectorC);

	return 0;
}
