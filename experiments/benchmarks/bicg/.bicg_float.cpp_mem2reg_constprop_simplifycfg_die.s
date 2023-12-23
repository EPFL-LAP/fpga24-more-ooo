	.text
	.file	"bicg_float.cpp"
	.globl	_Z10bicg_floatPA100_fPfS1_S1_S1_ # -- Begin function _Z10bicg_floatPA100_fPfS1_S1_S1_
	.p2align	4, 0x90
	.type	_Z10bicg_floatPA100_fPfS1_S1_S1_,@function
_Z10bicg_floatPA100_fPfS1_S1_S1_:       # @_Z10bicg_floatPA100_fPfS1_S1_S1_
	.cfi_startproc
# %bb.0:                                # %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset %rbp, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register %rbp
	xorl	%eax, %eax
	movq	%rcx, -8(%rbp)          # 8-byte Spill
	movq	%rdx, -16(%rbp)         # 8-byte Spill
	movq	%rsi, -24(%rbp)         # 8-byte Spill
	movq	%rdi, -32(%rbp)         # 8-byte Spill
	movq	%r8, -40(%rbp)          # 8-byte Spill
	movl	%eax, -44(%rbp)         # 4-byte Spill
	jmp	.LBB0_1
.LBB0_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_2 Depth 2
	movl	-44(%rbp), %eax         # 4-byte Reload
	xorl	%ecx, %ecx
	movl	%eax, %edx
	movl	%edx, %esi
	movq	-16(%rbp), %rdi         # 8-byte Reload
	movss	(%rdi,%rsi,4), %xmm0    # xmm0 = mem[0],zero,zero,zero
	movl	%eax, -48(%rbp)         # 4-byte Spill
	movss	%xmm0, -52(%rbp)        # 4-byte Spill
	movl	%ecx, -56(%rbp)         # 4-byte Spill
.LBB0_2:                                # %for.body3
                                        #   Parent Loop BB0_1 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movl	-56(%rbp), %eax         # 4-byte Reload
	movss	-52(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movl	-48(%rbp), %ecx         # 4-byte Reload
	movl	%ecx, %edx
	movl	%edx, %esi
	movl	%eax, %edx
	movl	%edx, %edi
	imulq	$400, %rsi, %rsi        # imm = 0x190
	movq	-32(%rbp), %r8          # 8-byte Reload
	addq	%rsi, %r8
	shlq	$2, %rdi
	addq	%rdi, %r8
	movss	(%r8), %xmm1            # xmm1 = mem[0],zero,zero,zero
	movl	%eax, %edx
	movl	%edx, %esi
	movq	-24(%rbp), %rdi         # 8-byte Reload
	movss	(%rdi,%rsi,4), %xmm2    # xmm2 = mem[0],zero,zero,zero
	movl	%ecx, %edx
	movl	%edx, %esi
	movaps	%xmm1, %xmm3
	movq	-40(%rbp), %r8          # 8-byte Reload
	mulss	(%r8,%rsi,4), %xmm3
	addss	%xmm3, %xmm2
	movl	%eax, %edx
	movl	%edx, %esi
	movss	%xmm2, (%rdi,%rsi,4)
	movl	%eax, %edx
	movl	%edx, %esi
	movq	-8(%rbp), %r9           # 8-byte Reload
	mulss	(%r9,%rsi,4), %xmm1
	addss	%xmm1, %xmm0
	addl	$1, %eax
	cmpl	$30, %eax
	movaps	%xmm0, %xmm1
	movss	%xmm0, -60(%rbp)        # 4-byte Spill
	movss	%xmm1, -52(%rbp)        # 4-byte Spill
	movl	%eax, -56(%rbp)         # 4-byte Spill
	jb	.LBB0_2
# %bb.3:                                # %for.end
                                        #   in Loop: Header=BB0_1 Depth=1
	movl	-48(%rbp), %eax         # 4-byte Reload
	movl	%eax, %ecx
	movl	%ecx, %edx
	movq	-16(%rbp), %rsi         # 8-byte Reload
	movss	-60(%rbp), %xmm0        # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rsi,%rdx,4)
	addl	$1, %eax
	cmpl	$30, %eax
	movl	%eax, %ecx
	movl	%eax, -64(%rbp)         # 4-byte Spill
	movl	%ecx, -44(%rbp)         # 4-byte Spill
	jb	.LBB0_1
# %bb.4:                                # %for.end22
	movl	-64(%rbp), %eax         # 4-byte Reload
	popq	%rbp
	retq
.Lfunc_end0:
	.size	_Z10bicg_floatPA100_fPfS1_S1_S1_, .Lfunc_end0-_Z10bicg_floatPA100_fPfS1_S1_S1_
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
	subq	$41632, %rsp            # imm = 0xA2A0
.LBB1_1:                                # %for.body
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB1_2 Depth 2
                                        #       Child Loop BB1_3 Depth 3
	xorl	%eax, %eax
	movl	%eax, -41604(%rbp)      # 4-byte Spill
	jmp	.LBB1_2
.LBB1_2:                                # %for.body3
                                        #   Parent Loop BB1_1 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB1_3 Depth 3
	movl	-41604(%rbp), %eax      # 4-byte Reload
	movl	%eax, -41608(%rbp)      # 4-byte Spill
	callq	rand
	movl	$100, %ecx
	cltd
	idivl	%ecx
	addl	$1, %edx
	cvtsi2ssl	%edx, %xmm0
	movl	-41608(%rbp), %ecx      # 4-byte Reload
	movl	%ecx, %edx
	movl	%edx, %esi
	movss	%xmm0, -40400(%rbp,%rsi,4)
	callq	rand
	movl	$100, %ecx
	cltd
	idivl	%ecx
	addl	$1, %edx
	cvtsi2ssl	%edx, %xmm0
	movl	-41608(%rbp), %ecx      # 4-byte Reload
	movl	%ecx, %edx
	movl	%edx, %esi
	movss	%xmm0, -40800(%rbp,%rsi,4)
	callq	rand
	movl	$100, %ecx
	cltd
	idivl	%ecx
	addl	$1, %edx
	cvtsi2ssl	%edx, %xmm0
	movl	-41608(%rbp), %ecx      # 4-byte Reload
	movl	%ecx, %edx
	movl	%edx, %esi
	movss	%xmm0, -41200(%rbp,%rsi,4)
	callq	rand
	xorl	%ecx, %ecx
	movl	$100, %edx
	movl	%edx, -41612(%rbp)      # 4-byte Spill
	cltd
	movl	-41612(%rbp), %edi      # 4-byte Reload
	idivl	%edi
	addl	$1, %edx
	cvtsi2ssl	%edx, %xmm0
	movl	-41608(%rbp), %edx      # 4-byte Reload
	movl	%edx, %r8d
	movl	%r8d, %esi
	movss	%xmm0, -41600(%rbp,%rsi,4)
	movl	%ecx, -41616(%rbp)      # 4-byte Spill
.LBB1_3:                                # %for.body32
                                        #   Parent Loop BB1_1 Depth=1
                                        #     Parent Loop BB1_2 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	movl	-41616(%rbp), %eax      # 4-byte Reload
	movl	%eax, -41620(%rbp)      # 4-byte Spill
	callq	rand
	leaq	-40000(%rbp), %rcx
	movl	$100, %edx
	movl	%edx, -41624(%rbp)      # 4-byte Spill
	cltd
	movl	-41624(%rbp), %esi      # 4-byte Reload
	idivl	%esi
	addl	$1, %edx
	cvtsi2ssl	%edx, %xmm0
	movl	-41608(%rbp), %edx      # 4-byte Reload
	movl	%edx, %edi
	movl	%edi, %r8d
	movl	-41620(%rbp), %edi      # 4-byte Reload
	movl	%edi, %r9d
	movl	%r9d, %r10d
	imulq	$400, %r8, %r8          # imm = 0x190
	addq	%r8, %rcx
	shlq	$2, %r10
	addq	%r10, %rcx
	movss	%xmm0, (%rcx)
	addl	$1, %edi
	cmpl	$100, %edi
	movl	%edi, -41616(%rbp)      # 4-byte Spill
	jb	.LBB1_3
# %bb.4:                                # %for.inc43
                                        #   in Loop: Header=BB1_2 Depth=2
	movl	-41608(%rbp), %eax      # 4-byte Reload
	addl	$1, %eax
	cmpl	$100, %eax
	movl	%eax, -41604(%rbp)      # 4-byte Spill
	jb	.LBB1_2
# %bb.5:                                # %for.inc46
                                        #   in Loop: Header=BB1_1 Depth=1
	xorl	%eax, %eax
	movb	%al, %cl
	testb	$1, %cl
	jne	.LBB1_1
	jmp	.LBB1_6
.LBB1_6:                                # %for.end48
	leaq	-41600(%rbp), %r8
	leaq	-41200(%rbp), %rcx
	leaq	-40800(%rbp), %rdx
	leaq	-40400(%rbp), %rsi
	leaq	-40000(%rbp), %rdi
	callq	_Z10bicg_floatPA100_fPfS1_S1_S1_
	xorl	%r9d, %r9d
	movl	%eax, -41628(%rbp)      # 4-byte Spill
	movl	%r9d, %eax
	addq	$41632, %rsp            # imm = 0xA2A0
	popq	%rbp
	retq
.Lfunc_end1:
	.size	main, .Lfunc_end1-main
	.cfi_endproc
                                        # -- End function

	.ident	"clang version 6.0.1 (http://llvm.org/git/clang.git 2f27999df400d17b33cdd412fdd606a88208dfcc) (http://llvm.org/git/llvm.git 5136df4d089a086b70d452160ad5451861269498)"
	.section	".note.GNU-stack","",@progbits
