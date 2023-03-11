# Experiments in DOS programming in x86 Assembly Language

Assembly language was my second programming language after BASIC, which I learned at school using GW-BASIC. On the summer after school, my dad gave me two programming books. One was for PASCAL and the other was for assembly Language. While I have forgotten the name of the author of the PASCAL book, it was not the case with the assembly language book. Leo J. Scanlon's **8086/8088/80286 Assembly Language book** got me so hooked that even though I have never used assembly language in any professional capacity, it became a hobby of mine though high school and early college, when assembly language was no longer in vogue.

I am collecting in this repository (hopefully) all my recent experiments with the language, plus any other projects/source codes I manage to dig up in my paper archives. I making lots of effort to test them in DOSBOX as well as in VirtualBox (using MS0-DOS 5/6.22, DR DOS 6.0, and FreeDOS). For the assembler and linker, I am mainly using Borland's TurboAssembler (TASM) version 5.1. With minor (if any) modifications, it could be made to work with Microsofts Macro Assembler (MASM).


## Expanded memory library (emmdemo)

- Library for checking availability of expanded memory
- Testing whether expanded memory manager is working
- Getting EMM info: base page frame segment and number of unallocated/free/total pages
- Allocate/de-allocate pages
- Map/unmap pages
- TODO: copy to/from mapped pages
