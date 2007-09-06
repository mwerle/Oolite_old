# Project: fdlibm

CC = gcc.exe
SRCDIR = /d/devlibs/SpiderMonkey/js/src/fdlibm

OBJECTS= \
$(SRCDIR)/e_acos.o \
$(SRCDIR)/e_acosh.o \
$(SRCDIR)/e_asin.o \
$(SRCDIR)/e_atan2.o \
$(SRCDIR)/e_atanh.o \
$(SRCDIR)/e_cosh.o \
$(SRCDIR)/e_exp.o \
$(SRCDIR)/e_fmod.o \
$(SRCDIR)/e_gamma.o \
$(SRCDIR)/e_gamma_r.o \
$(SRCDIR)/e_hypot.o \
$(SRCDIR)/e_j0.o \
$(SRCDIR)/e_j1.o \
$(SRCDIR)/e_jn.o \
$(SRCDIR)/e_lgamma.o \
$(SRCDIR)/e_lgamma_r.o \
$(SRCDIR)/e_log.o \
$(SRCDIR)/e_log10.o \
$(SRCDIR)/e_pow.o \
$(SRCDIR)/e_rem_pio2.o \
$(SRCDIR)/e_remainder.o \
$(SRCDIR)/e_scalb.o \
$(SRCDIR)/e_sinh.o \
$(SRCDIR)/e_sqrt.o \
$(SRCDIR)/k_cos.o \
$(SRCDIR)/k_rem_pio2.o \
$(SRCDIR)/k_sin.o \
$(SRCDIR)/k_standard.o \
$(SRCDIR)/k_tan.o \
$(SRCDIR)/s_asinh.o \
$(SRCDIR)/s_atan.o \
$(SRCDIR)/s_cbrt.o \
$(SRCDIR)/s_ceil.o \
$(SRCDIR)/s_copysign.o \
$(SRCDIR)/s_cos.o \
$(SRCDIR)/s_erf.o \
$(SRCDIR)/s_expm1.o \
$(SRCDIR)/s_fabs.o \
$(SRCDIR)/s_finite.o \
$(SRCDIR)/s_floor.o \
$(SRCDIR)/s_frexp.o \
$(SRCDIR)/s_ilogb.o \
$(SRCDIR)/s_isnan.o \
$(SRCDIR)/s_ldexp.o \
$(SRCDIR)/s_lib_version.o \
$(SRCDIR)/s_log1p.o \
$(SRCDIR)/s_logb.o \
$(SRCDIR)/s_matherr.o \
$(SRCDIR)/s_modf.o \
$(SRCDIR)/s_nextafter.o \
$(SRCDIR)/s_rint.o \
$(SRCDIR)/s_scalbn.o \
$(SRCDIR)/s_signgam.o \
$(SRCDIR)/s_significand.o \
$(SRCDIR)/s_sin.o \
$(SRCDIR)/s_tan.o \
$(SRCDIR)/s_tanh.o \
$(SRCDIR)/w_acos.o \
$(SRCDIR)/w_acosh.o \
$(SRCDIR)/w_asin.o \
$(SRCDIR)/w_atan2.o \
$(SRCDIR)/w_atanh.o \
$(SRCDIR)/w_cosh.o \
$(SRCDIR)/w_exp.o \
$(SRCDIR)/w_fmod.o \
$(SRCDIR)/w_gamma.o \
$(SRCDIR)/w_gamma_r.o \
$(SRCDIR)/w_hypot.o \
$(SRCDIR)/w_j0.o \
$(SRCDIR)/w_j1.o \
$(SRCDIR)/w_jn.o \
$(SRCDIR)/w_lgamma.o \
$(SRCDIR)/w_lgamma_r.o \
$(SRCDIR)/w_log.o \
$(SRCDIR)/w_log10.o \
$(SRCDIR)/w_pow.o \
$(SRCDIR)/w_remainder.o \
$(SRCDIR)/w_scalb.o \
$(SRCDIR)/w_sinh.o \
$(SRCDIR)/w_sqrt.o

LIBS = -llibm
BIN  = libfdlibm.a
CFLAGS = -DJS_THREADSAFE -D_IEEE_LIBM -DWIN32 -D_WINDOWS -s
.c.o: $(CC) -c $(CFLAGS) -o $@ $*.c

$(BIN): $(OBJECTS)
	ar r $(BIN) $(OBJECTS)
	ranlib $(BIN)