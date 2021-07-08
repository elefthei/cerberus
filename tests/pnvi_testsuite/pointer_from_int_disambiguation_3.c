#include "refinedc.h"

#include <stdio.h>
#include <string.h> 
#include <stdint.h>
#include <inttypes.h>
int y=2, x=1;
int main() {
  int *p = &x+1;
  int *q = &y;
  uintptr_t i = (uintptr_t)p;
  uintptr_t j = (uintptr_t)q;
  if (memcmp(&p, &q, sizeof(p)) == 0) {
#if defined(ANNOT)
    int *r = copy_alloc_id(i, q);
#else
    int *r = (int *)i;
#endif
    *r=11;
    r=r-1;  // is this free of UB?
    *r=12;  // and this?    
    printf("x=%d y=%d *q=%d *r=%d\n",x,y,*q,*r); 
  }
}
