#include <iostream>
#include <sys/time.h>

/**
 * mergesort.cu
 * a one-file c++ / cuda program for performing mergesort on the GPU
 * While the program execution is fairly slow, most of its runnning time
 *  is spent allocating memory on the GPU.
 * For a more complex program that performs many calculations,
 *  running on the GPU may provide a significant boost in performance
 */

// helper for main()
long readList(long**);

// data[], size, threads, blocks, 
void mergesort(long*, long, dim3, dim3);
// A[]. B[], size, width, slices, nThreads
__global__ void gpu_mergesort(long*, long*, long, long, long, dim3*, dim3*);
__device__ void gpu_bottomUpMerge(long*, long*, long, long, long);

#define min(a, b) (a < b ? a : b)

int main(int argc, char** argv) {

    dim3 threadsPerBlock;
    dim3 blocksPerGrid;

    threadsPerBlock.x = 16;
    threadsPerBlock.y = 1;
    threadsPerBlock.z = 1;

    blocksPerGrid.x = 1;
    blocksPerGrid.y = 1;
    blocksPerGrid.z = 1;

    long* data;
    long size = 64;
    data = (long *)malloc(size*sizeof(long));
    for (int i = 0; i < size; ++i) {
	data[i] = rand() % 1000;
    }
    
    std::cout<<"Initial array: ";
    for (int i = 0; i < size; i++) {
        std::cout << data[i] << ' ';
    }
    std::cout<<"\n\n";

    mergesort(data, size, threadsPerBlock, blocksPerGrid);
    std::cout<<"Output: ";
    for (int i = 0; i < size; i++) {
        std::cout << data[i] << ' ';
    }
    std::cout<<'\n';
}

void mergesort(long* data, long size, dim3 threadsPerBlock, dim3 blocksPerGrid) {

    //
    // Allocate two arrays on the GPU
    // we switch back and forth between them during the sort
    //
    long* D_data;
    long* D_swp;
    dim3* D_threads;
    dim3* D_blocks;
    
    // Actually allocate the two arrays
    cudaMalloc((void**) &D_data, size * sizeof(long));
    cudaMalloc((void**) &D_swp, size * sizeof(long));

    // Copy from our input list into the first array
    cudaMemcpy(D_data, data, size * sizeof(long), cudaMemcpyHostToDevice);
 
    //
    // Copy the thread / block info to the GPU as well
    //
    cudaMalloc((void**) &D_threads, sizeof(dim3));
    cudaMalloc((void**) &D_blocks, sizeof(dim3));

    cudaMemcpy(D_threads, &threadsPerBlock, sizeof(dim3), cudaMemcpyHostToDevice);
    cudaMemcpy(D_blocks, &blocksPerGrid, sizeof(dim3), cudaMemcpyHostToDevice);

    long* A = D_data;
    long* B = D_swp;

    long nThreads = threadsPerBlock.x * threadsPerBlock.y * threadsPerBlock.z *
                    blocksPerGrid.x * blocksPerGrid.y * blocksPerGrid.z;

    //
    // Slice up the list and give pieces of it to each thread, letting the pieces grow
    // bigger and bigger until the whole list is sorted
    //
    for (int width = 2; width < (size << 1); width <<= 1) {
        long slices = size / ((nThreads) * width) + 1;

        // Actually call the kernel
        gpu_mergesort<<<blocksPerGrid, threadsPerBlock>>>(A, B, size, width, slices, D_threads, D_blocks);
	cudaDeviceSynchronize();

        // Switch the input / output arrays instead of copying them around
        A = A == D_data ? D_swp : D_data;
        B = B == D_data ? D_swp : D_data;
    }

    cudaMemcpy(data, A, size * sizeof(long), cudaMemcpyDeviceToHost);
    
    // Free the GPU memory
    cudaFree(A);
    cudaFree(B);
}

// GPU helper function
// calculate the id of the current thread
__device__ unsigned int getIdx(dim3* threads, dim3* blocks) {
    int x;
    return threadIdx.x +
           threadIdx.y * (x  = threads->x) +
           threadIdx.z * (x *= threads->y) +
           blockIdx.x  * (x *= threads->z) +
           blockIdx.y  * (x *= blocks->z) +
           blockIdx.z  * (x *= blocks->y);
}

//
// Perform a full mergesort on our section of the data.
//
__global__ void gpu_mergesort(long* source, long* dest, long size, long width, long slices, dim3* threads, dim3* blocks) {
    unsigned int idx = getIdx(threads, blocks);
    long start = width*idx*slices, 
         middle, 
         end;

    for (long slice = 0; slice < slices; slice++) {
        if (start >= size)
            break;

        middle = min(start + (width >> 1), size);
        end = min(start + width, size);
        gpu_bottomUpMerge(source, dest, start, middle, end);
        start += width;
    }
}

//
// Finally, sort something
// gets called by gpu_mergesort() for each slice
//
__device__ void gpu_bottomUpMerge(long* source, long* dest, long start, long middle, long end) {
    long i = start;
    long j = middle;
    for (long k = start; k < end; k++) {
        if (i < middle && (j >= end || source[i] < source[j])) {
            dest[k] = source[i];
            i++;
        } else {
            dest[k] = source[j];
            j++;
        }
    }
}
