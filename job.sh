#!/bin/bash
#SBATCH --job-name=Merge_Sort_MPI
#SBATCH --output=output.log
#SBATCH --error=error.log
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=00:10:00

# Run your command or executable
mpirun -n 16 ./Merge_Sort_MPI 1000000000
