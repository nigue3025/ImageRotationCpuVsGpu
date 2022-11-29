
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include<iostream>
#include <stdio.h>
#include<vector>
#include<time.h>
//#define printMatrix
cudaError_t rotationCuda(int* a, std::vector<std::vector<int>> matrix);




__global__ void showThreadNo()
{
	// int tid = blockDim.x * blockIdx.x + threadIdx.x;
	printf("idx %d, idy %d\n", threadIdx.x, threadIdx.y);// << std::endl;

}

__global__ void rotateKernel_badVersion(int matrixSz, int halfsz, int* matrix)
{
	// int tid = blockDim.x * blockIdx.x + threadIdx.x;

	int tid = blockIdx.x * blockDim.x + threadIdx.x;
	int sz = matrixSz;

	//printf("(%d):%d\n", tid,matrix[tid]);

	// int halfsz = ceil((double)sz / 2.0);
	int tempx = 0, tempy = 0;
	int temp = 0, tempPrev = 0;


	for (int j = tid; j < sz - 1 - tid; j++)
	{
		tempx = tid;
		tempy = j;
		for (int l = 0; l < 4; l++)
		{
			//temp = matrix[tempy][sz - 1 - tempx];
			temp = matrix[tempy * (matrixSz)+(sz - 1 - tempx)];
			if (l > 0)
				matrix[tempy * (matrixSz)+(sz - 1 - tempx)] = tempPrev;
			else
				matrix[tempy * matrixSz + (sz - 1 - tempx)] = matrix[tempx * matrixSz + tempy];
			int oldTempx = tempx;
			tempx = tempy;
			tempy = sz - 1 - oldTempx;
			tempPrev = temp;
		}
	}


}

__global__ void rotateKernel(int matrixSz, int halfsz, int* matrix)
{
	int tid = blockDim.x * blockIdx.x + threadIdx.x;

	int y_axis = ((tid + 1) / matrixSz);
	int sz = matrixSz;
	int x_axis = threadIdx.x;

	//if ()return;
	if (x_axis < sz - 1 - y_axis && x_axis >= y_axis && y_axis > halfsz)
	{
		int temp, tempPrev;
		int tempx = y_axis;
		int tempy = x_axis;
		for (int edgeSide = 0; edgeSide < 4; edgeSide++)
		{
			temp = matrix[tempy * (matrixSz)+(sz - 1 - tempx)];
			if (edgeSide > 0)
				matrix[tempy * (matrixSz)+(sz - 1 - tempx)] = tempPrev;
			else
				matrix[tempy * matrixSz + (sz - 1 - tempx)] = matrix[tempx * matrixSz + tempy];
			int oldTempx = tempx;
			tempx = tempy;
			tempy = sz - 1 - oldTempx;
			tempPrev = temp;
		}
	}


}

int main()
{
	int GivenMatrixSizeN = 15000;
	cudaDeviceSynchronize();
	std::vector<std::vector<int>>matrix = std::vector<std::vector<int>>(GivenMatrixSizeN);
	int count = 0;
	//generate input matrix array data
	for (int i = 0; i < GivenMatrixSizeN; i++)
		for (int j = 0; j < GivenMatrixSizeN; j++)
			matrix[i].push_back(++count);
	int* oneDImage = new int[GivenMatrixSizeN * GivenMatrixSizeN];
	cudaError_t cudaStatus = rotationCuda(oneDImage, matrix);

	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "addWithCuda failed!");
		return 1;
	}


	// cudaDeviceReset must be called before exiting in order for profiling and
	// tracing tools such as Nsight and Visual Profiler to show complete traces.
	//cudaStatus = cudaDeviceReset();
	//if (cudaStatus != cudaSuccess) {
	//	fprintf(stderr, "cudaDeviceReset failed!");
	//	return 1;
	//}

	return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t rotationCuda(int* OneDMatrix, std::vector<std::vector<int>> matrix)
{
	int* dev_matrix = 0;
	int size = matrix.size() * matrix[0].size();
	cudaError_t cudaStatus;


	// Choose which GPU to run on, change this on a multi-GPU system.
	cudaStatus = cudaSetDevice(0);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
		goto Error;
	}



	cudaStatus = cudaMalloc((void**)&dev_matrix, size * sizeof(int));
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMalloc failed!");
		goto Error;
	}


	// Copy input vectors from host memory to GPU buffers.
	int* dst = dev_matrix;
	auto t0 = clock();
	for (auto& vec : matrix)
	{
		auto sz = vec.size();
		cudaStatus = cudaMemcpy(dst, &vec[0], vec.size() * sizeof(int), cudaMemcpyHostToDevice);
		dst = dst + sz;
		if (cudaStatus != cudaSuccess) {
			fprintf(stderr, "cudaMemcpy failed!");
			goto Error;
		}
	}
	auto t1 = clock();


	int thdsize = ceil((double)matrix.size() / 2.0);
	int blockSize = 1;

	// Launch a kernel on the GPU
	
	//if (matrix.size() > 32)
	//{
	//	blockSize = matrix.size() / 32;
	//	thdsize = 32;

	//}
	//rotateKernel_badVersion << <blockSize, thdsize >> > (matrix.size(), ceil((double)size / 2.0), dev_matrix);

	if (matrix.size() * matrix.size() > 32)
	{
		blockSize = ceil((double)matrix.size() / 32.0);
		thdsize = 32;
	}
	rotateKernel << <blockSize, thdsize >> > (matrix.size(), ceil((double)size / 2.0), dev_matrix);

	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
		goto Error;
	}

	// Copy output vector from GPU buffer to host memory.
	cudaStatus = cudaMemcpy(OneDMatrix, dev_matrix, size * sizeof(int), cudaMemcpyDeviceToHost);
	if (cudaStatus != cudaSuccess) {
		fprintf(stderr, "cudaMemcpy failed!");
		goto Error;

	}
	auto t2 = clock();
	std::cout << t2 - t1 << " ms ellapsed\n"; //omit time evaluation of cudaMalloc (can be reused after initialization)
	std::cout << t2 - t0 << " ms ellapsed(with cudaMemcpy)\n";

#ifdef printMatrix
	for (int i = 0; i < matrix.size(); i++)
	{
		for (int j = 0; j < matrix.size(); j++)
		{
			std::cout << OneDMatrix[i * matrix.size() + j] << ",";
		}
		std::cout << std::endl;
	}
#endif

	system("pause");
Error:
	cudaFree(dev_matrix);


	return cudaStatus;
}
