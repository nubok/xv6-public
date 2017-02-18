#include "asm.h"
#include "memlayout.h"
#include "mmu.h"
#include "boot_macros.S"
#include "entry_macros.S"
	
# Each non-boot CPU ("AP") is started up in response to a STARTUP
# IPI from the boot CPU.  Section B.4.2 of the Multi-Processor
# Specification says that the AP will start in real mode with CS:IP
# set to XY00:0000, where XY is an 8-bit value sent with the
# STARTUP. Thus this code must start at a 4096-byte boundary.
#
# Because this code sets DS to zero, it must sit
# at an address in the low 2^16 bytes.
#
# Startothers (in main.c) sends the STARTUPs one at a time.
# It copies this code (start) at 0x7000.  It puts the address of
# a newly allocated per-core stack in start-4,the address of the
# place to jump to (mpenter) in start-8, and the physical address
# of entrypgdir in start-12.
#
# This code combines elements of bootasm.S and entry.S.

.code16           
.globl start
start:
  CLI_AND_ZERO_DS_ES_SS
  SWITCH_TO_PROTECTED_MODE_AND_JUMP

.code32  # Tell assembler to generate 32-bit code now.
start32:
  SETUP_PROTECTED_MODE_DATA_SEGMENT_REGISTERS
  TURN_ON_PAGE_SIZE_EXTENSION

  # Use entrypgdir as our initial page table
  movl    (start-12), %eax
  movl    %eax, %cr3

  TURN_ON_PAGING

  # Switch to the stack allocated by startothers()
  movl    (start-4), %esp
  # Call mpenter()
  call	 *(start-8)

  TRIGGER_BOCHS_BREAKPOINT_AND_HALT

BOOTSTRAP_GDT

