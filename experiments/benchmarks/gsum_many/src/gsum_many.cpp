
//------------------------------------------------------------------------
// Jianyi Cheng, DSS
// https://zenodo.org/record/3561115
//------------------------------------------------------------------------


#include <stdlib.h>
#include "gsum_many.h"

int gsum_many(in_float_t a[N], out_float_t c[N]) { 
	int i;
 	float d;
	int kk = 0;
	for(kk = 0; kk < 10; kk++) {
		float s= 0.0;
		for (i=0; i<1000; i++){
           d = a[i];
	       if (d >= 0) 
	      	s += (((((d+(float)0.64)*d+(float)0.7)*d+(float)0.21)*d+(float)0.33)*d);
    	}
    	c[kk] = s;
	}
	
	return kk;

}

#define AMOUNT_OF_TEST 1

int main(void){
	in_float_t a[AMOUNT_OF_TEST][N];

	in_int_t aya[AMOUNT_OF_TEST][N];

	in_float_t b[AMOUNT_OF_TEST][N];

    out_float_t c[AMOUNT_OF_TEST][N];

    
	for(int i = 0; i < AMOUNT_OF_TEST; ++i){
		for(int j = 0; j < N; ++j){
    		a[i][j] = (float) 1 - j;
			b[i][j] = (float) j + 10;

			c[i][j] = (float) j + 10;
			aya[i][j] = 1 - j;

			if (j%10 == 0)
			   	a[i][j] = j;
		}
	}

	int i = 0;
	gsum_many(a[i],c[i]);

}




