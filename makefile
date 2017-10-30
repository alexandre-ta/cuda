### TEST MAKEFILE ###
CC44    = /usr/bin/gcc-4.4
CC47 	= /usr/bin/gcc
NVCC  	= /opt/cuda/bin/nvcc
MPICC	= /usr/bin/mpicc
CFLAGS  = -g -O0 -openmp

all: openmp_test openmpi_test cuda_test

openmp_test: openmp.c
	${CC47} -fopenmp openmp.c -o openmp_test

openmpi_test: openmpi.c
	${MPICC} openmpi.c -o openmpi_test

cuda_test: cuda.cu
	${NVCC} cuda.cu -o cuda_test

clean: 
	rm *.o -rf
	rm *test -rf
