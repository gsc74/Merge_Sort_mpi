CXX = mpic++
CC = gcc
nvcc = nvcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -lm

all: Merge_Sort_MPI mergeSortCUDA mergeSortOMP

Merge_Sort_MPI: Merge_Sort_MPI.cpp
	$(CXX) $(CFLAGS) -o Merge_Sort_MPI Merge_Sort_MPI.cpp $(LDFLAGS)

mergeSortCUDA: mergeSortCUDA.cu
	$(nvcc) -o mergeSortCUDA mergeSortCUDA.cu $(LDFLAGS)

mergeSortOMP: mergeSortOMP.c
	$(CC) $(CFLAGS) -o mergeSortOMP mergeSortOMP.c $(LDFLAGS) -fopenmp

clean:
	rm -f Merge_Sort_MPI mergeSortCUDA mergeSortOMP
