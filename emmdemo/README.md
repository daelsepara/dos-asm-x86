# Expanded memory library (emmdemo)

- Check availability of expanded memory
- Test whether expanded memory manager is working
- Get expanded memory driver info:
  - base page frame segment
  - total number of unallocated/free pages
  - total number of pages
  - EMS Version (v2.0 library only)
- Allocate/de-allocate pages
- Map/unmap logical pages to physical pages
- Copy to/from mapped pages

## Library versions

[Version 1.0](v1) - Pass parameters in registers

[Version 2.0](v2) - Pass parameters through the stack using **__stdcall** calling convention