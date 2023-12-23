	.text
	.file	"gemm_float.cpp"
	.globl	_Z10gemm_floatffPA30_fS0_S0_ # -- Begin function _Z10gemm_floatffPA30_fS0_S0_
	.p2align	4, 0x90
	.type	_Z10gemm_floatffPA30_fS0_S0_,@function
_Z10gemm_floatffPA30_fS0_S0_:           # @_Z10gemm_floatffPA30_fS0_S0_
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
	movss	%xmm1, -20(%rbp)        # 4-byte Spill
	movss	%xmm0, -24(%rbp)        # 4-byte Spill
	movq	%rdx, -32(%rbp)         # 8-byte Spill
	movl	%eax, -36(%rbp)         # 4-byte Spill
	jmp	.LBB0_1
.LBB0_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
                                        #       Child Loop BB0_3 Depth 3
	movl	-36(%rbp), %eax         # 4-byte Reload
	xorl	%ecx, %ecx
	movl	%eax, -40(%rbp)         # 4-byte Spill
	movl	%ecx, -44(%rbp)         # 4-byte Spill
.LBB0_2:                                # %for.body3
                                        #   Parent Loop BB0_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB0_3 Depth 3
	movl	-44(%rbp), %eax         # 4-byte Reload
	xorl	%ecx, %ecx
	movl	-40(%rbp), %edx         # 4-byte Reload
	movl	%edx, %esi
	movl	%esi, %edi
	movl	%eax, %esi
	movl	%esi, %r8d
	imulq	$120, %rdi, %rdi
	movq	-32(%rbp), %r9          # 8-byte Reload
	addq	%rdi, %r9
	shlq	$2, %r8
	addq	%r8, %r9
	movss	-20(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	mulss	(%r9), %xmm0
	movl	%eax, -48(%rbp)         # 4-byte Spill
	movss	%xmm0, -52(%rbp)        # 4-byte Spill
	movl	%ecx, -56(%rbp)         # 4-byte Spill
.LBB0_3:                                # %for.body8
                                        #   Parent Loop BB0_1 Depth=1
                                        #     Parent Loop BB0_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	movl	-56(%rbp), %eax         # 4-byte Reload
	movss	-52(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movl	-40(%rbp), %ecx         # 4-byte Reload
	movl	%ecx, %edx
	movl	%edx, %esi
	movl	%eax, %edx
	movl	%edx, %edi
	imulq	$120, %rsi, %rsi
	movq	-16(%rbp), %r8          # 8-byte Reload
	addq	%rsi, %r8
	shlq	$2, %rdi
	addq	%rdi, %r8
	movss	-24(%rbp), %xmm1        # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	mulss	(%r8), %xmm1
	movl	%eax, %edx
	movl	%edx, %esi
	movl	-48(%rbp), %edx         # 4-byte Reload
	movl	%edx, %r9d
	movl	%r9d, %edi
	imulq	$120, %rsi, %rsi
	movq	-8(%rbp), %r8           # 8-byte Reload
	addq	%rsi, %r8
	shlq	$2, %rdi
	addq	%rdi, %r8
	mulss	(%r8), %xmm1
	addss	%xmm1, %xmm0
	addl	$1, %eax
	cmpl	$20, %eax
	movaps	%xmm0, %xmm1
	movss	%xmm0, -60(%rbp)        # 4-byte Spill
	movss	%xmm1, -52(%rbp)        # 4-byte Spill
	movl	%eax, -56(%rbp)         # 4-byte Spill
	jb	.LBB0_3
# %bb.4:                                # %for.end
                                        #   in Loop: Header=BB0_2 Depth=2
	movl	-40(%rbp), %eax         # 4-byte Reload
	movl	%eax, %ecx
	movl	%ecx, %edx
	movl	-48(%rbp), %ecx         # 4-byte Reload
	movl	%ecx, %esi
	movl	%esi, %edi
	imulq	$120, %rdx, %rdx
	movq	-32(%rbp), %r8          # 8-byte Reload
	addq	%rdx, %r8
	shlq	$2, %rdi
	addq	%rdi, %r8
	movss	-60(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%r8)
	addl	$1, %ecx
	cmpl	$20, %ecx
	movl	%ecx, %esi
	movl	%ecx, -64(%rbp)         # 4-byte Spill
	movl	%esi, -44(%rbp)         # 4-byte Spill
	jb	.LBB0_2
# %bb.5:                                # %for.inc26
                                        #   in Loop: Header=BB0_1 Depth=1
	movl	-40(%rbp), %eax         # 4-byte Reload
	addl	$1, %eax
	cmpl	$20, %eax
	movl	%eax, -36(%rbp)         # 4-byte Spill
	jb	.LBB0_1
# %bb.6:                                # %for.end28
	movl	-64(%rbp), %eax         # 4-byte Reload
	popq	%rbp
	retq
.Lfunc_end0:
	.size	_Z10gemm_floatffPA30_fS0_S0_, .Lfunc_end0-_Z10gemm_floatffPA30_fS0_S0_
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
	subq	$10848, %rsp            # imm = 0x2A60
.LBB1_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_2 Depth 2
                                        #       Child Loop BB1_3 Depth 3
	xorl	%eax, %eax
	movss	.LCPI1_0(%rip), %xmm0   # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, -4(%rbp)
	movss	%xmm0, -8(%rbp)
	movl	%eax, -10820(%rbp)      # 4-byte Spill
.LBB1_2:                                # %for.body5
                                        #   Parent Loop BB1_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB1_3 Depth 3
	movl	-10820(%rbp), %eax      # 4-byte Reload
	xorl	%ecx, %ecx
	movl	%eax, -10824(%rbp)      # 4-byte Spill
	movl	%ecx, -10828(%rbp)      # 4-byte Spill
.LBB1_3:                                # %for.body8
                                        #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	movl	-10828(%rbp), %eax      # 4-byte Reload
	movl	%eax, -10832(%rbp)      # 4-byte Spill
	callq	rand
	leaq	-3616(%rbp), %rcx
	movl	$2, %edx
	movl	%edx, -10836(%rbp)      # 4-byte Spill
	cltd
	movl	-10836(%rbp), %esi      # 4-byte Reload
	idivl	%esi
	cvtsi2ssl	%edx, %xmm0
	movl	-10824(%rbp), %edx      # 4-byte Reload
	movl	%edx, %edi
	movl	%edi, %r8d
	movl	-10832(%rbp), %edi      # 4-byte Reload
	movl	%edi, %r9d
	movl	%r9d, %r10d
	imulq	$120, %r8, %r8
	addq	%r8, %rcx
	shlq	$2, %r10
	addq	%r10, %rcx
	movss	%xmm0, (%rcx)
	callq	rand
	movss	.LCPI1_0(%rip), %xmm0   # xmm0 = mem[0],zero,zero,zero
	leaq	-10816(%rbp), %rcx
	leaq	-7216(%rbp), %r8
	movl	$3, %edx
	movl	%edx, -10840(%rbp)      # 4-byte Spill
	cltd
	movl	-10840(%rbp), %esi      # 4-byte Reload
	idivl	%esi
	cvtsi2ssl	%edx, %xmm1
	movl	-10824(%rbp), %edx      # 4-byte Reload
	movl	%edx, %edi
	movl	%edi, %r10d
	movl	-10832(%rbp), %edi      # 4-byte Reload
	movl	%edi, %r9d
	movl	%r9d, %r11d
	imulq	$120, %r10, %r10
	addq	%r10, %r8
	shlq	$2, %r11
	addq	%r11, %r8
	movss	%xmm1, (%r8)
	movl	%edx, %r9d
	movl	%r9d, %r8d
	movl	%edi, %r9d
	movl	%r9d, %r10d
	imulq	$120, %r8, %r8
	addq	%r8, %rcx
	shlq	$2, %r10
	addq	%r10, %rcx
	movss	%xmm0, (%rcx)
	addl	$1, %edi
	cmpl	$30, %edi
	movl	%edi, -10828(%rbp)      # 4-byte Spill
	jb	.LBB1_3
# %bb.4:                                # %for.inc30
                                        #   in Loop: Header=BB1_2 Depth=2
	movl	-10824(%rbp), %eax      # 4-byte Reload
	addl	$1, %eax
	cmpl	$30, %eax
	movl	%eax, -10820(%rbp)      # 4-byte Spill
	jb	.LBB1_2
# %bb.5:                                # %for.inc33
                                        #   in Loop: Header=BB1_1 Depth=1
	xorl	%eax, %eax
	movb	%al, %cl
	testb	$1, %cl
	jne	.LBB1_1
	jmp	.LBB1_6
.LBB1_6:                                # %for.end35
	leaq	-10816(%rbp), %rdx
	leaq	-7216(%rbp), %rsi
	leaq	-3616(%rbp), %rdi
	movss	-4(%rbp), %xmm0         # xmm0 = mem[0],zero,zero,zero
	movss	-8(%rbp), %xmm1         # xmm1 = mem[0],zero,zero,zero
	callq	_Z10gemm_floatffPA30_fS0_S0_
	xorl	%ecx, %ecx
	movl	%eax, -10844(%rbp)      # 4-byte Spill
	movl	%ecx, %eax
	addq	$10848, %rsp            # imm = 0x2A60
	popq	%rbp
	retq
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function

	.ident	"clang version 6.0.1 (http://llvm.org/git/clang.git 2f27999df400d17b33cdd412fdd606a88208dfcc) (http://llvm.org/git/llvm.git 5136df4d089a086b70d452160ad5451861269498)"
	.section	".note.GNU-stack","",@progbits
