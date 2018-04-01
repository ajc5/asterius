# Asterius: A Haskell to WebAssembly compiler

[![CircleCI](https://circleci.com/gh/tweag/asterius/tree/master.svg?style=shield)](https://circleci.com/gh/tweag/asterius/tree/master)
[![AppVeyor](https://ci.appveyor.com/api/projects/status/github/tweag/asterius?branch=master&svg=true)](https://ci.appveyor.com/project/TerrorJack/asterius?branch=master)

A Haskell to WebAssembly compiler. Project status: **pre-alpha**, in active development, still takes time before an initial example works.

What's already present:

* A framework that hijacks the normal `ghc` pipeline and retrieves an
  in-memory representation of raw Cmm.
* A test suite for booting that compiles `ghc-prim`, `integer-simple` and `base`.
* Complete raw Haskell bindings of `binaryen`, in the `binaryen` package.
* A serializable IR, roughly mapping to `binaryen` IR.

Currently working on:

* A custom linker that merges modules, handles relocations and supports tail-calls.

What comes next:

* An RTS written from scratch in native WebAssembly. Will implement
  enough primops & libc stubs for an MVP(Minimum Viable Product).
* A test suite for the generated WebAssembly code.

See [`ROADMAP.md`](ROADMAP.md) for a more detailed roadmap. The haddock documentation of the latest commit is available [here](https://tweag.github.io/asterius/index.html).

## Building

Tested on Linux x64 and Windows x64.

`asterius` requires a build of recent `ghc-head` which uses `integer-simple` and disables tables-next-to-code. On Linux, you can use `haskell.compiler.ghcAsterius`. The relevant Nix expressions can be found [here](https://github.com/TerrorJack/nixpkgs/tree/4cc8c2955fe132c3c780cdce41746ea77fcfe687). There is a binary cache available at `https://canis.sapiens.moe/`. (Not signed at the moment)

On Windows, a manually built `ghc-head` binary dist is available. It's already contained in [`stack.yaml`](stack.yaml), so for Windows users a plain `stack build` should work out of the box.

Extra dependencies:

* `cmake`/`make`/`g++`: For building in-tree [`binaryen`](https://github.com/WebAssembly/binaryen)
* `autoconf`: For booting `ghc-prim`/`base`
* `nodejs`: For running tests
* `stack`

Simply run `stack build asterius`. Set `MAKEFLAGS=-j8` to pass flags to `make` for parallel building of `binaryen`. Run `stack test asterius:ahc-boot` to test if booting works.

## Differences with [WebGHC](https://webghc.github.io/)

* Doesn't depend on Emscripten/LLVM. There is no plan to port the C runtime and support C libraries, at least for now.
* Windows is supported.

## Sponsors

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
[<img src="https://www.tweag.io/img/tweag-med.png" height="65">](http://tweag.io)

Asterius is maintained by [Tweag I/O](http://tweag.io/).

Have questions? Need help? Tweet at
[@tweagio](http://twitter.com/tweagio).
