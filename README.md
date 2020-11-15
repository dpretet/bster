# BSTer

<p align="center">
  <img width="325" height="215" src="./doc/icon.png">
</p>

[![Build Status](https://travis-ci.org/dpretet/bster.svg?branch=master)](https://travis-ci.org/dpretet/bster)

## Introduction

This repository owns a binary search tree algorithm implemented as a RTL IP for
FPGA and ASIC. It is designed with SystemVerilog.

- the [functional specification](doc/functional_spec.md)
- the [info document](doc/info.md) provides basic information about this type
  of algorithm
- the [interface document](doc/interface.md) provides information about the
  interface of the IP and how to use it

## External dependencies

BSTer simulation relies for simulation on:

- [Icarus Verilog](http://iverilog.icarus.com)
- [SVUT](https://github.com/dpretet/svut)

## License

This IP core is licensed under MIT license. It grants nearly all rights to use,
modify and distribute these sources. However, consider to contribute and provide
updates to this core if you add feature and fix, would be greatly appreciated :)
