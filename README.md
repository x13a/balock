# balock

Bruteforce OEM and NCK codes for Balong V7R11.

Huawei E5573**, E5577**, E8372h, E3372h..

Credits to rust3028, Decker, forth32..

## Installation

```sh
$ make
$ make install
```
or
```sh
$ brew tap x13a/tap
$ brew install x13a/tap/balock
```

## Usage

```text
balock [-h|V] <HEX1> <HEX2>

[-h] * Print help and exit
[-V] * Print version and exit
```

## AT

OEM:
```text
$ AT^NVRDEX=50502,0,128
```

NCK:
```text
$ AT^NVRDEX=50503,0,128
```
