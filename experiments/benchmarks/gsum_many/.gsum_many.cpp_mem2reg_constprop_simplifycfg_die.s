	.text
	.file	"gsum_many.cpp"
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2               # -- Begin function _Z9gsum_manyPfS_
.LCPI0_0:
	.long	1051260355              # float 0.330000013
.LCPI0_1:
	.long	1045891645              # float 0.209999993
.LCPI0_2:
	.long	1060320051              # float 0.699999988
.LCPI0_3:
	.long	1059313418              # float 0.639999986
	.text
	.globl	_Z9gsum_manyPfS_
	.p2align	4, 0x90
	.type	_Z9gsum_manyPfS_,@function
_Z9gsum_manyPfS_:                       # @_Z9gsum_manyPfS_
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	xorl	%eax, %eax
	movq	%rdi, -8(%rbp)          # 8-byte Spill
	movq	%rsi, -16(%rbp)         # 8-byte Spill
	movl	%eax, -20(%rbp)         # 4-byte Spill
	jmp	.LBB0_1
.LBB0_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
	movl	-20(%rbp), %eax         # 4-byte Reload
	xorps	%xmm0, %xmm0
	xorl	%ecx, %ecx
	movl	%eax, -24(%rbp)         # 4-byte Spill
	movss	%xmm0, -28(%rbp)        # 4-byte Spill
	movl	%ecx, -32(%rbp)         # 4-byte Spill
.LBB0_2:                                # %for.body3
                                        #   Parent Loop BB0_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	-32(%rbp), %eax         # 4-byte Reload
	movss	-28(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	xorps	%xmm1, %xmm1
	movl	%eax, %ecx
	movl	%ecx, %edx
	movq	-8(%rbp), %rsi          # 8-byte Reload
	movss	(%rsi,%rdx,4), %xmm2    # xmm2 = mem[0],zero,zero,zero
	ucomiss	%xmm1, %xmm2
	movaps	%xmm0, %xmm1
	movl	%eax, -36(%rbp)         # 4-byte Spill
	movss	%xmm0, -40(%rbp)        # 4-byte Spill
	movss	%xmm2, -44(%rbp)        # 4-byte Spill
	movss	%xmm1, -48(%rbp)        # 4-byte Spill
	jb	.LBB0_4
# %bb.3:                                # %if.then
                                        #   in Loop: Header=BB0_2 Depth=2
	movss	.LCPI0_0(%rip), %xmm0   # xmm0 = mem[0],zero,zero,zero
	movss	.LCPI0_1(%rip), %xmm1   # xmm1 = mem[0],zero,zero,zero
	movss	.LCPI0_2(%rip), %xmm2   # xmm2 = mem[0],zero,zero,zero
	movss	.LCPI0_3(%rip), %xmm3   # xmm3 = mem[0],zero,zero,zero
	movss	-44(%rbp), %xmm4        # 4-byte Reload
                                        # xmm4 = mem[0],zero,zero,zero
	addss	%xmm3, %xmm4
	movss	-44(%rbp), %xmm3        # 4-byte Reload
                                        # xmm3 = mem[0],zero,zero,zero
	mulss	%xmm3, %xmm4
	addss	%xmm2, %xmm4
	mulss	%xmm3, %xmm4
	addss	%xmm1, %xmm4
	mulss	%xmm3, %xmm4
	addss	%xmm0, %xmm4
	mulss	%xmm3, %xmm4
	movss	-40(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	addss	%xmm4, %xmm0
	movss	%xmm0, -48(%rbp)        # 4-byte Spill
.LBB0_4:                                # %for.inc
                                        #   in Loop: Header=BB0_2 Depth=2
	movss	-48(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movl	-36(%rbp), %eax         # 4-byte Reload
	addl	$1, %eax
	cmpl	$1000, %eax             # imm = 0x3E8
	movaps	%xmm0, %xmm1
	movss	%xmm0, -52(%rbp)        # 4-byte Spill
	movss	%xmm1, -28(%rbp)        # 4-byte Spill
	movl	%eax, -32(%rbp)         # 4-byte Spill
	jb	.LBB0_2
# %bb.5:                                # %for.end
                                        #   in Loop: Header=BB0_1 Depth=1
	movl	-24(%rbp), %eax         # 4-byte Reload
	movl	%eax, %ecx
	movl	%ecx, %edx
	movq	-16(%rbp), %rsi         # 8-byte Reload
	movss	-52(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rsi,%rdx,4)
	addl	$1, %eax
	cmpl	$10, %eax
	movl	%eax, %ecx
	movl	%eax, -56(%rbp)         # 4-byte Spill
	movl	%ecx, -20(%rbp)         # 4-byte Spill
	jb	.LBB0_1
# %bb.6:                                # %for.end16
	movl	-56(%rbp), %eax         # 4-byte Reload
	popq	%rbp
	retq
.Lfunc_end0:
	.size	_Z9gsum_manyPfS_, .Lfunc_end0-_Z9gsum_manyPfS_
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2               # -- Begin function main
.LCPI1_0:
	.long	1092616192              # float 10
.LCPI1_1:
	.long	3212836864              # float -1
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
	subq	$8016, %rsp             # imm = 0x1F50
.LBB1_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_2 Depth 2
	xorl	%eax, %eax
	movl	%eax, -8004(%rbp)       # 4-byte Spill
	jmp	.LBB1_2
.LBB1_2:                                # %for.body3
                                        #   Parent Loop BB1_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	-8004(%rbp), %eax       # 4-byte Reload
	movl	$10, %ecx
	movss	.LCPI1_0(%rip), %xmm0   # xmm0 = mem[0],zero,zero,zero
	movss	.LCPI1_1(%rip), %xmm1   # xmm1 = mem[0],zero,zero,zero
	movl	%eax, %edx
	movl	%edx, %esi
	movss	%xmm1, -4000(%rbp,%rsi,4)
	cvtsi2ssl	%eax, %xmm1
	addss	%xmm0, %xmm1
	movl	%eax, %edx
	movl	%edx, %esi
	movss	%xmm1, -8000(%rbp,%rsi,4)
	movl	%eax, -8008(%rbp)       # 4-byte Spill
	xorl	%edx, %edx
	divl	%ecx
	cmpl	$0, %edx
	jne	.LBB1_4
# %bb.3:                                # %if.then
                                        #   in Loop: Header=BB1_2 Depth=2
	jmp	.LBB1_4
.LBB1_4:                                # %for.inc
                                        #   in Loop: Header=BB1_2 Depth=2
	movl	-8008(%rbp), %eax       # 4-byte Reload
	addl	$1, %eax
	cmpl	$1000, %eax             # imm = 0x3E8
	movl	%eax, -8004(%rbp)       # 4-byte Spill
	jb	.LBB1_2
# %bb.5:                                # %for.inc25
                                        #   in Loop: Header=BB1_1 Depth=1
	xorl	%eax, %eax
	movb	%al, %cl
	testb	$1, %cl
	jne	.LBB1_1
	jmp	.LBB1_6
.LBB1_6:                                # %for.end27
	leaq	-8000(%rbp), %rsi
	leaq	-4000(%rbp), %rdi
	callq	_Z9gsum_manyPfS_
	xorl	%ecx, %ecx
	movl	%eax, -8012(%rbp)       # 4-byte Spill
	movl	%ecx, %eax
	addq	$8016, %rsp             # imm = 0x1F50
	popq	%rbp
	retq
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function

	.ident	"clang version 6.0.1 (http://llvm.org/git/clang.git 2f27999df400d17b33cdd412fdd606a88208dfcc) (http://llvm.org/git/llvm.git 5136df4d089a086b70d452160ad5451861269498)"
	.section	".note.GNU-stack","",@progbits
