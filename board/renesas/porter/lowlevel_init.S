/*
 * board/renesas/porter/lowlevel_init.S
 *     This file is Porter low level initialize.
 *
 * Copyright (C) 2015 Renesas Electronics Corporation
 * Copyright (C) 2015 Cogent Embedded, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#include <config.h>
#include <linux/linkage.h>

ENTRY(lowlevel_init)
	mrc	p15, 0, r4, c0, c0, 5 /* mpidr */
	orr	r4, r4, r4, lsr #6
	and	r4, r4, #7 /* id 0-3 = ca15.0,1,2,3 */

	b do_lowlevel_init

	.pool

/*
 * Only CPU ID #0 comes here
 */
	.align  4
do_lowlevel_init:

	/* surpress wfe if ca15 */
	tst r4, #4
	mrceq p15, 0, r0, c1, c0, 1	/* actlr */
	orreq r0, r0, #(1<<7)
	mcreq p15, 0, r0, c1, c0, 1

	/* and set l2 latency */
	mrc p15, 0, r0, c0, c0, 5	/* r0 = MPIDR */
	and r0, r0, #0xf00
	lsr r0, r0, #8
	tst r0, #1			/* only need for cluster 0 */
	bne _exit_init_l2_a15

	mrc p15, 1, r0, c9, c0, 2	/* r0 = L2CTLR */
	and r1, r0, #7
	cmp r1, #3			/* has already been set up */
	bicne r0, r0, #0xe7
	orrne r0, r0, #0x83		/* L2CTLR[7:6] + L2CTLR[2:0] */
	mcrne p15, 1, r0, c9, c0, 2
_exit_init_l2_a15:
	ldr	r3, =(CONFIG_SYS_INIT_SP_ADDR)
	sub	sp, r3, #4
	str	lr, [sp]

	/* initialize system */
	bl s_init

	ldr	lr, [sp]
	mov	pc, lr
	nop
ENDPROC(lowlevel_init)
	.ltorg
