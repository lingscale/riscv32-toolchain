#!/bin/tcsh

setenv SRC $HOME/crossrv/src
setenv WORK $HOME/crossrv/work
setenv CROSS_TOOLS $HOME/.tools

mkdir ${CROSS_TOOLS}/sys-root
setenv SYSROOT ${CROSS_TOOLS}/sys-root

setenv BINUTILS_SRC ${SRC}/binutils-2.33.1
setenv GCC_SRC ${SRC}/gcc-9.2.0
setenv NEWLIB_SRC  ${SRC}/newlib-cygwin

setenv CROSS_HOST amd64-unknown-freebsd12.0
setenv CROSS_TARGET riscv32-unknown-elf

#binutils
mkdir ${WORK}/binutils
cd ${WORK}/binutils
setenv AR ar
setenv AS as
${BINUTILS_SRC}/configure --prefix=${CROSS_TOOLS} \
--build=${CROSS_HOST} --host=${CROSS_HOST} --target=${CROSS_TARGET} \
--with-sysroot=${SYSROOT} \
--with-lib-path=${SYSROOT}/usr/lib \
--with-mpc=/usr/local --with-mpfr=/usr/local --with-gmp=/usr/local \
--with-isl=/usr/local
make configure-host
make
make install


#gcc-static
mkdir ${WORK}/gcc-static
cd ${WORK}/gcc-static
setenv PATH ${CROSS_TOOLS}/bin:$PATH
${GCC_SRC}/configure --prefix=${CROSS_TOOLS} \
--build=${CROSS_HOST} --host=${CROSS_HOST} --target=${CROSS_TARGET} \
--with-arch=rv32i --with-abi=ilp32 --with-tune=rocket \
--with-sysroot=${SYSROOT} \
--with-local-prefix=${SYSROOT} \
--with-mpc=/usr/local --with-mpfr=/usr/local --with-gmp=/usr/local \
--with-isl=/usr/local \
--disable-shared --disable-threads --disable-tls \
--without-headers --with-newlib --disable-decimal-float \
--disable-libquadmath --disable-libada --disable-libssp --disable-libstdcxx \
--disable-libgomp --disable-nls --disable-tm-clone-registry \
--disable-multilib \
--with-system-zlib \
--enable-languages=c,c++
make all-gcc all-target-libgcc
make install-gcc install-target-libgcc


#newlib
#git clone git://sourceware.org/git/newlib-cygwin.git
mkdir ${WORK}/newlib
cd ${WORK}/newlib
setenv CFLAGS_FOR_TARGET "-O2 -D_POSIX_MODE -mcmodel=medlow"
setenv CXXFLAGS_FOR_TARGET "-O2 -D_POSIX_MODE -mcmodel=medlow"
${NEWLIB_SRC}/configure --prefix=${CROSS_TOOLS} \
--build=${CROSS_HOST} --host=${CROSS_HOST} --target=${CROSS_TARGET} \
--enable-newlib-io-long-double \
--enable-newlib-io-long-long \
--enable-newlib-io-c99-formats \
--enable-newlib-register-fini
make
make install

#newlib-nano
mkdir ${WORK}/newlib-nano
cd ${WORK}/newlib-nano
setenv CFLAGS_FOR_TARGET "-Os -ffunction-sections -fdata-sections"
setenv CXXFLAGS_FOR_TARGET "-Os -ffunction-sections -fdata-sections"
${NEWLIB_SRC}/configure --prefix=${WORK}/newlib-nano/install-newlib-nano \
--build=${CROSS_HOST} --host=${CROSS_HOST} --target=${CROSS_TARGET} \
--enable-newlib-reent-small \
--disable-newlib-fvwrite-in-streamio \
--disable-newlib-fseek-optimization \
--disable-newlib-wide-orient \
--enable-newlib-nano-malloc \
--disable-newlib-unbuf-stream-opt \
--enable-lite-exit \
--enable-newlib-global-atexit \
--enable-newlib-nano-formatted-io \
--disable-newlib-supplied-syscalls \
--disable-nls
make
make install

# Copy nano library files into newlib install dir.
cp ${WORK}/newlib-nano/install-newlib-nano/${CROSS_TARGET}/lib/libc.a ${CROSS_TOOLS}/${CROSS_TARGET}/lib/libc_nano.a
cp ${WORK}/newlib-nano/install-newlib-nano/${CROSS_TARGET}/lib/libg.a ${CROSS_TOOLS}/${CROSS_TARGET}/lib/libg_nano.a
cp ${WORK}/newlib-nano/install-newlib-nano/${CROSS_TARGET}/lib/libgloss.a ${CROSS_TOOLS}/${CROSS_TARGET}/lib/libgloss_nano.a
cp ${WORK}/newlib-nano/install-newlib-nano/${CROSS_TARGET}/lib/crt0.o ${CROSS_TOOLS}/${CROSS_TARGET}/lib/ctr0.o
# Copy nano header files into newlib install dir.
mkdir -p ${CROSS_TOOLS}/${CROSS_TARGET}/include/newlib-nano
cp ${WORK}/newlib-nano/install-newlib-nano/${CROSS_TARGET}/include/newlib.h ${CROSS_TOOLS}/${CROSS_TARGET}/include/newlib-nano/newlib.h

# final gcc
mkdir ${WORK}/gcc
cd ${WORK}/gcc
unsetenv CFLAGS_FOR_TARGET
unsetenv CXXFLAGS_FOR_TARGET
${GCC_SRC}/configure --prefix=${CROSS_TOOLS} \
--build=${CROSS_HOST} --host=${CROSS_HOST} --target=${CROSS_TARGET} \
--with-arch=rv32i --with-abi=ilp32 --with-tune=rocket \
--with-sysroot=${SYSROOT} \
--with-local-prefix=${SYSROOT} \
--with-mpc=/usr/local --with-mpfr=/usr/local --with-gmp=/usr/local \
--with-isl=/usr/local \
--disable-shared --disable-threads --enable-tls \
--with-native-system-header-dir=/include --with-newlib --disable-decimal-float \
--disable-libquadmath --disable-libada --disable-libssp --disable-libstdcxx \
--disable-libgomp --disable-nls --disable-tm-clone-registry \
--disable-multilib \
--with-system-zlib \
--enable-languages=c,c++
make
make install

