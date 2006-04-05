/*
 *  TextureUtilities.c
 *  Oolite
 *
 *  Created by Jens Ayton on 2006-02-07.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include "TextureUtilities.h"
#import <Carbon/Carbon.h>
#import <Accelerate/Accelerate.h>


#if __ppc__
// PPC systems love explicit paralellism and use of lots of registers.
static void Swizzle_RGBA_ARGB_AltiVec(char *inBuffer, unsigned inPixelCount);


static inline _Bool HaveAltivec(void)
{
	OSErr				err;
	long				response;
	static uint8_t		answer;
	
	if (0 == answer)
	{
		err = Gestalt(gestaltPowerPCProcessorFeatures, &response);
		answer = (!err && (response & (1 << gestaltPowerPCHasVectorInstructions))) ? 2 : 1;
	}
	return answer - 1;
}


void Swizzle_RGBA_ARGB(char *inBuffer, unsigned inPixelCount)
{
	__builtin_prefetch(inBuffer, 1, 0);
	
	uint32_t			*pix;
	uint32_t			curr0, curr1, curr2, curr3, curr4, curr5, curr6, curr7,
						rgb0, rgb1, rgb2, rgb3, rgb4, rgb5, rgb6, rgb7,
						a0, a1, a2, a3, a4, a5, a6, a7;
	unsigned			loopCount;
	
	if (HaveAltivec())
	{
		Swizzle_RGBA_ARGB_AltiVec(inBuffer, inPixelCount);
		return;
	}
	
	loopCount = inPixelCount / 8;
	pix = (uint32_t *)inBuffer;
	do
	{
		curr0 = pix[0];
		curr1 = pix[1];
		curr2 = pix[2];
		curr3 = pix[3];
		curr4 = pix[4];
		curr5 = pix[5];
		curr6 = pix[6];
		curr7 = pix[7];
		
		a0 = (curr0 & 0xFF) << 24;
		a1 = (curr1 & 0xFF) << 24;
		a2 = (curr2 & 0xFF) << 24;
		a3 = (curr3 & 0xFF) << 24;
		a4 = (curr4 & 0xFF) << 24;
		a5 = (curr5 & 0xFF) << 24;
		a6 = (curr6 & 0xFF) << 24;
		a7 = (curr7 & 0xFF) << 24;
		rgb0 = curr0 >> 8;
		rgb1 = curr1 >> 8;
		rgb2 = curr2 >> 8;
		rgb3 = curr3 >> 8;
		rgb4 = curr4 >> 8;
		rgb5 = curr5 >> 8;
		rgb6 = curr6 >> 8;
		rgb7 = curr7 >> 8;
		
		pix[0] = a0 | rgb0;
		pix[1] = a1 | rgb1;
		pix[2] = a2 | rgb2;
		pix[3] = a3 | rgb3;
		pix[4] = a4 | rgb4;
		pix[5] = a5 | rgb5;
		pix[6] = a6 | rgb6;
		pix[7] = a7 | rgb7;
		pix += 8;
	} while (--loopCount);
	
	// Handle odd pixels at end
	loopCount = inPixelCount % 8;
	while (loopCount--)
	{
		curr0 = *pix;
		
		a0 = (curr0 & 0xFF) << 24;
		rgb0 = curr0 >> 8;
		
		*pix++ = a0 | rgb0;
	}
}


typedef union
{
	uint8_t				bytes[16];
	vUInt8				vec;
} VecBytesU8;


static void Swizzle_RGBA_ARGB_AltiVec(char *inBuffer, unsigned inPixelCount)
{
	vec_dststt(inBuffer, 256, 0);
	
	vUInt32				*pix;
	vUInt32				curr0, curr1, curr2, curr3;
	VecBytesU8			permBytes =
						{{
							3, 0, 1, 2,
							7, 4, 5, 6,
							11, 8, 9, 10,
							15, 12, 13, 14
						}};
	vUInt8				permMask = permBytes.vec;
	unsigned			loopCount;
	uint32_t			*pixS;
	uint32_t			currS, rgb, a;
	
	pix = (vUInt32 *)inBuffer;
	loopCount = inPixelCount / 16;
	do
	{
		curr0 = pix[0];
		curr1 = pix[1];
		curr2 = pix[2];
		curr3 = pix[3];
		
		// Note: second parameter is unused
		pix[0] = vec_perm(curr0, curr0, permMask);
		pix[1] = vec_perm(curr1, curr1, permMask);
		pix[2] = vec_perm(curr2, curr2, permMask);
		pix[3] = vec_perm(curr3, curr3, permMask);
		
		pix += 4;
		
	} while (--loopCount);
	
	pixS = (uint32_t *)pix;
	loopCount = inPixelCount % 16;
	while (loopCount--)
	{
		currS = *pixS;
		
		a = (currS & 0xFF) << 24;
		rgb = currS >> 8;
		
		*pixS++ = a | rgb;
	}
}

#else
// x86 systems, however, don’t do too well with explicit loop unrolling.

void Swizzle_RGBA_ARGB(char *inBuffer, unsigned inPixelCount)
{
	__builtin_prefetch(inBuffer, 1, 0);
	
	uint32_t			*pix;
	uint32_t			curr, rgb, a;
	
	assert(0 != inPixelCount);
	
	pix = (uint32_t *)inBuffer;
	do
	{
		curr = *pix;
		
		a = (curr & 0xFF) << 24;
		rgb = curr >> 8;
		
		*pix++ = a | rgb;
	} while (--inPixelCount);
}

#endif
