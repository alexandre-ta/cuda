#include <stdio.h>
#include "omp.h"

int main()
{
    int tid;
    omp_set_num_threads(4);
#pragma omp parallel num_threads(4) private(tid)
    {
        tid = omp_get_thread_num();
        fprintf(stdout, "Current thread: %d\n", tid);
    }
    return 0;
}
