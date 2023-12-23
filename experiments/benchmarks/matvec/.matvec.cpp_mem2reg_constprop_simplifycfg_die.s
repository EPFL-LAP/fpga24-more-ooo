	.text
	.file	"matvec.cpp"
	.globl	_Z6matvecPA30_fPfS1_    # -- Begin function _Z6matvecPA30_fPfS1_
	.p2align	4, 0x90
	.type	_Z6matvecPA30_fPfS1_,@function
_Z6matvecPA30_fPfS1_:                   # @_Z6matvecPA30_fPfS1_
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	xorl	%eax, %eax
	movq	%rsi, -8(%rbp)          # 8-byte Spill
	movq	%rdi, -16(%rbp)         # 8-byte Spill
	movq	%rdx, -24(%rbp)         # 8-byte Spill
	movl	%eax, -28(%rbp)         # 4-byte Spill
	jmp	.LBB0_1
.LBB0_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
	movl	-28(%rbp), %eax         # 4-byte Reload
	xorps	%xmm0, %xmm0
	xorl	%ecx, %ecx
	movl	%eax, -32(%rbp)         # 4-byte Spill
	movss	%xmm0, -36(%rbp)        # 4-byte Spill
	movl	%ecx, -40(%rbp)         # 4-byte Spill
.LBB0_2:                                # %for.body3
                                        #   Parent Loop BB0_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	-40(%rbp), %eax         # 4-byte Reload
	movss	-36(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movl	%eax, %ecx
	movl	%ecx, %edx
	movq	-8(%rbp), %rsi          # 8-byte Reload
	movss	(%rsi,%rdx,4), %xmm1    # xmm1 = mem[0],zero,zero,zero
	movl	-32(%rbp), %ecx         # 4-byte Reload
	movl	%ecx, %edi
	movl	%edi, %edx
	movl	%eax, %edi
	movl	%edi, %r8d
	imulq	$120, %rdx, %rdx
	movq	-16(%rbp), %r9          # 8-byte Reload
	addq	%rdx, %r9
	shlq	$2, %r8
	addq	%r8, %r9
	mulss	(%r9), %xmm1
	addss	%xmm1, %xmm0
	addl	$1, %eax
	cmpl	$30, %eax
	movaps	%xmm0, %xmm1
	movss	%xmm0, -44(%rbp)        # 4-byte Spill
	movss	%xmm1, -36(%rbp)        # 4-byte Spill
	movl	%eax, -40(%rbp)         # 4-byte Spill
	jb	.LBB0_2
# %bb.3:                                # %for.end
                                        #   in Loop: Header=BB0_1 Depth=1
	movl	-32(%rbp), %eax         # 4-byte Reload
	movl	%eax, %ecx
	movl	%ecx, %edx
	movq	-24(%rbp), %rsi         # 8-byte Reload
	movss	-44(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rsi,%rdx,4)
	addl	$1, %eax
	cmpl	$30, %eax
	movl	%eax, %ecx
	movl	%eax, -48(%rbp)         # 4-byte Spill
	movl	%ecx, -28(%rbp)         # 4-byte Spill
	jb	.LBB0_1
# %bb.4:                                # %for.end12
	movl	-48(%rbp), %eax         # 4-byte Reload
	popq	%rbp
	retq
.Lfunc_end0:
	.size	_Z6matvecPA30_fPfS1_, .Lfunc_end0-_Z6matvecPA30_fPfS1_
	.cfi_endproc
                                        # -- End function
	.globl	main                    # -- Begin function main
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
	subq	$3888, %rsp             # imm = 0xF30
.LBB1_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_2 Depth 2
                                        #       Child Loop BB1_3 Depth 3
	xorl	%eax, %eax
	movl	%eax, -3860(%rbp)       # 4-byte Spill
	jmp	.LBB1_2
.LBB1_2:                                # %for.body3
                                        #   Parent Loop BB1_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB1_3 Depth 3
	movl	-3860(%rbp), %eax       # 4-byte Reload
	movl	%eax, -3864(%rbp)       # 4-byte Spill
	callq	rand
	xorl	%ecx, %ecx
	movl	$100, %edx
	movl	%edx, -3868(%rbp)       # 4-byte Spill
	cltd
	movl	-3868(%rbp), %esi       # 4-byte Reload
	idivl	%esi
	cvtsi2ssl	%edx, %xmm0
	movl	-3864(%rbp), %edx       # 4-byte Reload
	movl	%edx, %edi
	movl	%edi, %r8d
	movss	%xmm0, -3728(%rbp,%r8,4)
	movl	%ecx, -3872(%rbp)       # 4-byte Spill
.LBB1_3:                                # %for.body8
                                        #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	movl	-3872(%rbp), %eax       # 4-byte Reload
	movl	%eax, -3876(%rbp)       # 4-byte Spill
	callq	rand
	leaq	-3600(%rbp), %rcx
	movl	$100, %edx
	movl	%edx, -3880(%rbp)       # 4-byte Spill
	cltd
	movl	-3880(%rbp), %esi       # 4-byte Reload
	idivl	%esi
	cvtsi2ssl	%edx, %xmm0
	movl	-3864(%rbp), %edx       # 4-byte Reload
	movl	%edx, %edi
	movl	%edi, %r8d
	movl	-3876(%rbp), %edi       # 4-byte Reload
	movl	%edi, %r9d
	movl	%r9d, %r10d
	imulq	$120, %r8, %r8
	addq	%r8, %rcx
	shlq	$2, %r10
	addq	%r10, %rcx
	movss	%xmm0, (%rcx)
	addl	$1, %edi
	cmpl	$30, %edi
	movl	%edi, -3872(%rbp)       # 4-byte Spill
	jb	.LBB1_3
# %bb.4:                                # %for.inc18
                                        #   in Loop: Header=BB1_2 Depth=2
	movl	-3864(%rbp), %eax       # 4-byte Reload
	addl	$1, %eax
	cmpl	$30, %eax
	movl	%eax, -3860(%rbp)       # 4-byte Spill
	jb	.LBB1_2
# %bb.5:                                # %for.inc21
                                        #   in Loop: Header=BB1_1 Depth=1
	xorl	%eax, %eax
	movb	%al, %cl
	testb	$1, %cl
	jne	.LBB1_1
	jmp	.LBB1_6
.LBB1_6:                                # %for.end23
	leaq	-3856(%rbp), %rdx
	leaq	-3728(%rbp), %rsi
	leaq	-3600(%rbp), %rdi
	callq	_Z6matvecPA30_fPfS1_
	xorl	%ecx, %ecx
	movl	%eax, -3884(%rbp)       # 4-byte Spill
	movl	%ecx, %eax
	addq	$3888, %rsp             # imm = 0xF30
	popq	%rbp
	retq
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function

	.ident	"clang version 6.0.1 (http://llvm.org/git/clang.git 2f27999df400d17b33cdd412fdd606a88208dfcc) (http://llvm.org/git/llvm.git 5136df4d089a086b70d452160ad5451861269498)"
	.section	".note.GNU-stack","",@progbits
