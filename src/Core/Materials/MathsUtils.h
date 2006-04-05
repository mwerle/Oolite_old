/*
 *  MathsUtils.h
 *  Miscelaneous mathematical utilities.
 *
 *	Created by Jens Ayton. This work is placed in the public domain. No warranties of any sort are
 *	provided.
 */

/*!	@header		MathsUtils.h
	@abstract	Miscelaneous mathematical utilities.
	
				Created by Jens Ayton.
	
				This work is placed in the public domain. No warranties of any sort are
				provided.
				
				PowerPC-specific optimisations are provided. These assume a G3 or better processor.
				The functions are declared inline, so C99 or C++ is required.
	@encoding	utf-8
*/

#ifndef INCLUDED_MATHSUTILS_h
#define INCLUDED_MATHSUTILS_h

#include <stdint.h>
#include <math.h>


// MATHSUTILS_h_PPC: whether to use PowerPC instruction intrinsics like __fsel().
#ifndef MATHSUTILS_h_PPC
	#if defined(__ppc__) || defined(__ppc64__)
		#define MATHSUTILS_h_PPC 1
	#else
		#define MATHSUTILS_h_PPC 0
	#endif
#endif


// MATHSUTILS_h_USE_BUILTIN_CLZ: whether to use GCC's __builtin_clz() function to count leading zeros
#ifndef MATHSUTILS_h_USE_BUILTIN_CLZ
	#if defined(__GNUC__) && (defined(__ppc__) || defined(__ppc64__))
		#define MATHSUTILS_h_USE_BUILTIN_CLZ	1
	#else
		#define MATHSUTILS_h_USE_BUILTIN_CLZ	0
	#endif
#endif


// MATHSUTILS_h_CONSTFUNC: attribute specifying that a function's value is dependant only on input with no side effects
#ifndef MATHSUTILS_h_CONSTFUNC
	#ifdef __GNUC__
		#define MATHSUTILS_h_CONSTFUNC	__attribute__((const))
	#else
		#define MATHSUTILS_h_CONSTFUNC
	#endif
#endif


#if MATHSUTILS_h_PPC
	#ifdef __MWERKS__
		#define MATHSUTILS_h_fsel(test, a, b)	__fsel(test, a, b)
		#define MATHSUTILS_h_fsels(test, a, b)	__fsel(test, a, b)
		#define MATHSUTILS_h_fres(val)			__fres(val)
		#define MATHSUTILS_h_fabs(val)			__fabs(val)
		#define MATHSUTILS_h_fabsf(val)			__fabsf(val)
	#elif defined(__GNUC__)
		// Taken from <gcc/darwin/default/ppc_intrinsics.h> under Mac OS X
		static inline double MATHSUTILS_h_fsel (double test, double a, double b) __attribute__((always_inline));
		static inline double MATHSUTILS_h_fsel (double test, double a, double b)
		{
		  double result;
		  __asm__ ("fsel %0,%1,%2,%3" 
					/* outputs:  */ : "=f" (result) 
					/* inputs:   */ : "f" (test), "f" (a), "f" (b));
		  return result;
		}
		
		static inline float MATHSUTILS_h_fsels (double test, double a, double b) __attribute__((always_inline));
		static inline float MATHSUTILS_h_fsels (double test, double a, double b)
		{
		  float result;
		  __asm__ ("fsel %0,%1,%2,%3" 
					/* outputs:  */ : "=f" (result) 
					/* inputs:   */ : "f" (test), "f" (a), "f" (b));
		  return result;
		}
		
		static inline float MATHSUTILS_h_fres (float val) __attribute__((always_inline));
		static inline float MATHSUTILS_h_fres (float val)
		{
		  float estimate;
		  __asm__ ("fres %0,%1" 
					/* outputs:  */ : "=f" (estimate) 
					/* inputs:   */ : "f" (val));
		  return estimate;
		}
		
		static inline double MATHSUTILS_h_fabs (double val) __attribute__((always_inline));
		static inline double MATHSUTILS_h_fabs (double val)
		{
			double result;
			__asm__ ("fabs %0, %1" 
					/* outputs:  */ : "=f" (result) 
					/* inputs:   */ : "f" (val));
			return result;
		}
		
		static inline float MATHSUTILS_h_fabsf (float val) __attribute__((always_inline));
		static inline float MATHSUTILS_h_fabsf (float val)
		{
			float result;
			__asm__ ("fabs %0, %1" 
					/* outputs:  */ : "=f" (result) 
					/* inputs:   */ : "f" (val));
			return result;
		}
	#else
		#warning Unknown compiler - don't know how to use PowerPC intrinsics. Using less efficient methods.
		#define MATHSUTILS_h_fsel(test, a, b)	(((test)>0)?(a):(b))
		#define MATHSUTILS_h_fsels(test, a, b)	MATHSUTILS_h_fsel(test, a, b)
		#define MATHSUTILS_h_fres(val)			(1.0/(val))
		#define MATHSUTILS_h_fabs(val)			fabs(val)
		#define MATHSUTILS_h_fabsf(n)			fabsf(val)
	#endif
#endif


/*!
	@function	RoundUpToPowerOf2
	@abstract	Round a short integer value up to a power of two.
	@discussion	Both implementations return 0 for a 0 input. This is technically incorrect - the
				answer should be 1 - but works well for allocation optimisation scenarios.
				
				The generic implementation comes from
				<a href="http://aggregate.org/MAGIC/">http://aggregate.org/MAGIC/</a>.
	@param		inValue		The source value.
	@result		The smallest power of two that is no smaller than inValue.
*/
static inline uint32_t RoundUpToPowerOf2(uint32_t x) MATHSUTILS_h_CONSTFUNC;


#if MATHSUTILS_h_USE_BUILTIN_CLZ || (MATHSUTILS_h_PPC && defined(__GNUC__))

static inline uint32_t RoundUpToPowerOf2(uint32_t inValue)
{
	return 0x80000000 >> (__builtin_clz(inValue - 1) - 1);
}

#elif MATHSUTILS_h_PPC

static inline uint32_t RoundUpToPowerOf2(uint32_t inValue)
{
	return 0x80000000 >> (__cntlzw(inValue - 1) - 1);
}

#else

static inline uint32_t RoundUpToPowerOf2(uint32_t x)
{
	x -= 1;
	x |= (x >> 1);
	x |= (x >> 2);
	x |= (x >> 4);
	x |= (x >> 8);
	x |= (x >> 16);
	return x + 1;
}

#endif


#ifdef __cplusplus
#define Clamp_0_1_d Clamp_0_1
#define Clamp_0_max_d Clamp_0_max
#endif

static inline float Clamp_0_1(float inValue) MATHSUTILS_h_CONSTFUNC;
static inline double Clamp_0_1_d(double inValue) MATHSUTILS_h_CONSTFUNC;
static inline float Clamp_0_max(float inValue, float inMax) MATHSUTILS_h_CONSTFUNC;
static inline double Clamp_0_max_d(double inValue, double inMax) MATHSUTILS_h_CONSTFUNC;

#if MATHSUTILS_h_PPC

static inline float Clamp_0_1(float inValue)
{
	float clampUpper = MATHSUTILS_h_fsels(inValue - 1.0f, 1.0f, inValue);
	return MATHSUTILS_h_fsels(inValue, clampUpper, 0.0f);
}

static inline double Clamp_0_1_d(double inValue)
{
	float clampUpper = MATHSUTILS_h_fsel(inValue - 1.0, 1.0, inValue);
	return MATHSUTILS_h_fsel(inValue, clampUpper, 0.0);
}

static inline float Clamp_0_max(float inValue, float inMax)
{
	float clampUpper = MATHSUTILS_h_fsels(inValue - inMax, inMax, inValue);
	return MATHSUTILS_h_fsels(inValue, clampUpper, 0.0f);
}

static inline double Clamp_0_max_d(double inValue, double inMax)
{
	double clampUpper = MATHSUTILS_h_fsel(inValue - inMax, inMax, inValue);
	return MATHSUTILS_h_fsel(inValue, clampUpper, 0.0);
}

#else


/*!
	@function	Clamp_0_1
	@abstract	Clamp a float value to the range [0..1].
	@param		inValue		The source value.
	@result		inValue if it is in the range [0..1]. 0 if inValue < 0. 1 if 1 < inValue.
	@seealso	Clamp_0_1_d
				Clamp_0_max
				Clamp_0_max_d
*/

static inline float Clamp_0_1(float inValue)
{
	return (inValue < 0.0f) ? 0.0f : ((inValue < 1.0f) ? inValue : 1.0f);
}


/*!
	@function	Clamp_0_1_d
	@abstract	Clamp a double value to the range [0..1].
	@param		inValue		The source value.
	@result		inValue if it is in the range [0..1]. 0 if inValue < 0. 1 if 1 < inValue.
	@seealso	Clamp_0_1
				Clamp_0_max_d
				Clamp_0_max
*/

static inline double Clamp_0_1_d(double inValue)
{
	return (inValue < 0.0) ? 0.0 : ((inValue < 1.0) ? inValue : 1.0);
}


/*!
	@function	Clamp_0_max
	@abstract	Clamp a float value to the range [0..inMax].
	@param		inValue		The source value.
	@param		inMax		The maximum value.
	@result		inValue if it is in the range [0..inMax]. 0 if inValue < 0. inMax if inMax < inValue.
	@seealso	Clamp_0_max_d
				Clamp_0_1
				Clamp_0_1_d
*/

static inline float Clamp_0_max(float inValue, float inMax)
{
	return (inValue < 0.0f) ? 0.0f : ((inValue < inMax) ? inValue : inMax);
}


/*!
	@function	Clamp_0_max_d
	@abstract	Clamp a double value to the range [0..inMax].
	@param		inValue		The source value.
	@param		inMax		The maximum value.
	@result		inValue if it is in the range [0..inMax]. 0 if inValue < 0. inMax if inMax < inValue.
	@seealso	Clamp_0_max
				Clamp_0_1_d
				Clamp_0_1
*/

static inline double Clamp_0_max_d(double inValue, double inMax)
{
	return (inValue < 0.0) ? 0.0 : ((inValue < inMax) ? inValue : inMax);
}

#endif


/*!
	@function	ApproxAtan2
	@abstract	Approximate evaluation of atan2(y, x) to within about 1%.
*/
static inline float ApproxAtan2(float inY, float inX) MATHSUTILS_h_CONSTFUNC;


#if MATHSUTILS_h_PPC

static inline float ApproxAtan2(float inY, float inX)
{
	const float pi = 3.14159265358979f;
	const float halfPi = 1.5707963267949f;
	const float factor = 0.2732395447351f;
	
	if (inX != 0.0f)
	{
		float ratio = MATHSUTILS_h_fres(inY) * inX;	// x/y -- not y/x, see below
		
		if (isnormal(ratio))
		{
			float result;
			
			// Estimate atan(1/ratio) (i.e., atan(y/x))
			if (MATHSUTILS_h_fabsf(ratio) > 1.0f)		// 1/ratio is between 1 and -1
			{
				result = MATHSUTILS_h_fres(ratio + factor * MATHSUTILS_h_fres(ratio));
			}
			else 
			{
				result = MATHSUTILS_h_fsel(ratio, halfPi, -halfPi);
				result -= ratio * MATHSUTILS_h_fres(1.0f + factor * ratio * ratio);
			}
			
			// adjust for sector
			if (inX < 0.0f)
			{
				result += MATHSUTILS_h_fsel(inY, pi, -pi);
			}
			return result;
		}
	}
	// else (denormal)
	
	if (inY > 0.0f) return halfPi;
	else if (inY < 0.0f) return -halfPi;
	else /* inY == 0 */ return MATHSUTILS_h_fsel(inX, 0.0f, pi);
}

#else

static inline float ApproxAtan2(float inY, float inX)
{
	const float pi = 3.14159265358979f;
	const float halfPi = 1.5707963267949f;
	const float factor = 0.2732395447351f;
	
	if (inX != 0.0f)
	{
		float ratio = inX / inY;	// x/y -- not y/x, see below
		
		if (isnormal(ratio))
		{
			float result;
			
			// Estimate atan(1/ratio) (i.e., atan(y/x))
			if (fabsf(ratio) > 1.0f)		// 1/ratio is between 1 and -1
			{
				result = 1.0f / (ratio + factor / ratio);
			}
			else 
			{
				if (ratio < 0) result = -halfPi;
				else result = halfPi;
				result -= ratio / (1.0f + factor * ratio * ratio);
			}
			
			// adjust for sector
			if (inX < 0.0f)
			{
				if (inY < 0.0f) result -= pi;
				else result += pi;
			}
			return result;
		}
	}
	// else (denormal)
	
	if (inY > 0.0f) return halfPi;
	else if (inY < 0.0f) return -halfPi;
	else /* inY == 0 */ return (0.0f <= inX) ? 0.0f : pi;
}

#endif

#endif	/* INCLUDED_MATHSUTILS_h */
