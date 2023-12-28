	.text
	.file	"gsum.cpp"
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2               # -- Begin function _Z4gsumPf
.LCPI0_0:
	.long	1051260355              # float 0.330000013
.LCPI0_1:
	.long	1045891645              # float 0.209999993
.LCPI0_2:
	.long	1060320051              # float 0.699999988
.LCPI0_3:
	.long	1059313418              # float 0.639999986
	.text
	.globl	_Z4gsumPf
	.p2align	4, 0x90
	.type	_Z4gsumPf,@function
_Z4gsumPf:                              # @_Z4gsumPf
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	xorps	%xmm0, %xmm0
	xorl	%eax, %eax
	movq	%rdi, -8(%rbp)          # 8-byte Spill
	movss	%xmm0, -12(%rbp)        # 4-byte Spill
	movl	%eax, -16(%rbp)         # 4-byte Spill
	jmp	.LBB0_1
.LBB0_1:                                # %for.body
                                        # =>This Inner Loop Header: Depth=1
	movl	-16(%rbp), %eax         # 4-byte Reload
	movss	-12(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	xorps	%xmm1, %xmm1
	movl	%eax, %ecx
	movl	%ecx, %edx
	movq	-8(%rbp), %rsi          # 8-byte Reload
	movss	(%rsi,%rdx,4), %xmm2    # xmm2 = mem[0],zero,zero,zero
	ucomiss	%xmm1, %xmm2
	movaps	%xmm0, %xmm1
	movl	%eax, -20(%rbp)         # 4-byte Spill
	movss	%xmm0, -24(%rbp)        # 4-byte Spill
	movss	%xmm2, -28(%rbp)        # 4-byte Spill
	movss	%xmm1, -32(%rbp)        # 4-byte Spill
	jb	.LBB0_3
# %bb.2:                                # %if.then
                                        #   in Loop: Header=BB0_1 Depth=1
	movss	.LCPI0_0(%rip), %xmm0   # xmm0 = mem[0],zero,zero,zero
	movss	.LCPI0_1(%rip), %xmm1   # xmm1 = mem[0],zero,zero,zero
	movss	.LCPI0_2(%rip), %xmm2   # xmm2 = mem[0],zero,zero,zero
	movss	.LCPI0_3(%rip), %xmm3   # xmm3 = mem[0],zero,zero,zero
	movss	-28(%rbp), %xmm4        # 4-byte Reload
                                        # xmm4 = mem[0],zero,zero,zero
	addss	%xmm3, %xmm4
	movss	-28(%rbp), %xmm3        # 4-byte Reload
                                        # xmm3 = mem[0],zero,zero,zero
	mulss	%xmm3, %xmm4
	addss	%xmm2, %xmm4
	mulss	%xmm3, %xmm4
	addss	%xmm1, %xmm4
	mulss	%xmm3, %xmm4
	addss	%xmm0, %xmm4
	mulss	%xmm3, %xmm4
	movss	-24(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	addss	%xmm4, %xmm0
	movss	%xmm0, -32(%rbp)        # 4-byte Spill
.LBB0_3:                                # %for.inc
                                        #   in Loop: Header=BB0_1 Depth=1
	movss	-32(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movl	-20(%rbp), %eax         # 4-byte Reload
	addl	$1, %eax
	cmpl	$1000, %eax             # imm = 0x3E8
	movl	%eax, %ecx
	movl	%eax, -36(%rbp)         # 4-byte Spill
	movss	%xmm0, -12(%rbp)        # 4-byte Spill
	movl	%ecx, -16(%rbp)         # 4-byte Spill
	jb	.LBB0_1
# %bb.4:                                # %for.end
	movl	-36(%rbp), %eax         # 4-byte Reload
	popq	%rbp
	retq
.Lfunc_end0:
	.size	_Z4gsumPf, .Lfunc_end0-_Z4gsumPf
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2               # -- Begin function main
.LCPI1_0:
	.long	1065353216              # float 1
	.text
	.globl	main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	subq	$4016, %rsp             # imm = 0xFB0
.LBB1_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_2 Depth 2
	xorl	%eax, %eax
	movl	%eax, -4004(%rbp)       # 4-byte Spill
	jmp	.LBB1_2
.LBB1_2:                                # %for.body3
                                        #   Parent Loop BB1_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	-4004(%rbp), %eax       # 4-byte Reload
	movl	$10, %ecx
	movss	.LCPI1_0(%rip), %xmm0   # xmm0 = mem[0],zero,zero,zero
	cvtsi2ssl	%eax, %xmm1
	subss	%xmm1, %xmm0
	movl	%eax, %edx
	movl	%edx, %esi
	movss	%xmm0, -4000(%rbp,%rsi,4)
	movl	%eax, -4008(%rbp)       # 4-byte Spill
	xorl	%edx, %edx
	divl	%ecx
	cmpl	$0, %edx
	jne	.LBB1_4
# %bb.3:                                # %if.then
                                        #   in Loop: Header=BB1_2 Depth=2
	jmp	.LBB1_4
.LBB1_4:                                # %for.inc
                                        #   in Loop: Header=BB1_2 Depth=2
	movl	-4008(%rbp), %eax       # 4-byte Reload
	addl	$1, %eax
	cmpl	$1000, %eax             # imm = 0x3E8
	movl	%eax, -4004(%rbp)       # 4-byte Spill
	jb	.LBB1_2
# %bb.5:                                # %for.inc27
                                        #   in Loop: Header=BB1_1 Depth=1
	xorl	%eax, %eax
	movb	%al, %cl
	testb	$1, %cl
	jne	.LBB1_1
	jmp	.LBB1_6
.LBB1_6:                                # %for.end29
	leaq	-4000(%rbp), %rdi
	callq	_Z4gsumPf
	xorl	%ecx, %ecx
	movl	%eax, -4012(%rbp)       # 4-byte Spill
	movl	%ecx, %eax
	addq	$4016, %rsp             # imm = 0xFB0
	popq	%rbp
	retq
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function

	.ident	"clang version 6.0.1 (http://llvm.org/git/clang.git 2f27999df400d17b33cdd412fdd606a88208dfcc) (http://llvm.org/git/llvm.git 5136df4d089a086b70d452160ad5451861269498)"
	.section	".note.GNU-stack","",@progbits
