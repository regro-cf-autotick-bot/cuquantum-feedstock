#!/bin/bash
set -ex

# integraty test
test -f $PREFIX/include/custatevec.h
test -f $PREFIX/include/cutensornet.h
test -f $PREFIX/include/cutensornet/types.h
test -f $PREFIX/lib/libcustatevec.so
test -f $PREFIX/lib/libcutensornet.so

# dlopen test
${GCC} test_load_elf.c -std=c99 -Werror -ldl -o test_load_elf
./test_load_elf $PREFIX/lib/libcustatevec.so
./test_load_elf $PREFIX/lib/libcutensornet.so

# compilation test
git clone -b v22.03.0 https://github.com/NVIDIA/cuQuantum.git sample_linux/
cd sample_linux/samples/
pushd .

NVCC_FLAGS=""
# Workaround __ieee128 error; see https://github.com/LLNL/blt/issues/341
if [[ $target_platform == linux-ppc64le && $cuda_compiler_version == 10.* ]]; then
    NVCC_FLAGS+=" -Xcompiler -mno-float128"
fi

cd custatevec
for f in ./*.cu; do
    echo $f
    error_log=$(nvcc $NVCC_FLAGS --std=c++11 -I$PREFIX/include -L$PREFIX/lib -lcustatevec $f -o $f.out 2>&1)
    echo $error_log
done
popd

cd cutensornet
for f in ./*.cu; do
    echo $f
    error_log=$(nvcc $NVCC_FLAGS --std=c++11 -I$PREFIX/include -L$PREFIX/lib -lcutensornet -lcutensor $f -o $f.out 2>&1)
    echo $error_log
done
