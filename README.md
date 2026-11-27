# ClaudeClang

Clang/LLVM 툴체인으로 C/C++ 코드를 작성·빌드하는 프로젝트입니다.

## 요구 사항
- Clang / LLVM (`clang`, `clang++`, `clang-format`, `clang-tidy`)
- CMake

## 빌드
```sh
cmake -S . -B build -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
cmake --build build
```
