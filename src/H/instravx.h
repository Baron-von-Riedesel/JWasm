/****************************************************************************
*
* Description:  AVX instructions with VEX prefix
*
****************************************************************************/

#if AVXSUPP
/*   tok                         cpu */
/* format: xmm|ymm, xmm|ymm|mem */
avxins (ADDPD,    vaddpd,        P_AVX, VX_L ) /* L, s */
avxins (ADDPS,    vaddps,        P_AVX, VX_L ) /* L, s */
avxins (ADDSD,    vaddsd,        P_AVX, 0 )    /* -, s */
avxins (ADDSS,    vaddss,        P_AVX, 0 )    /* -, s */
avxins (DIVPD,    vdivpd,        P_AVX, VX_L ) /* L, s */
avxins (DIVPS,    vdivps,        P_AVX, VX_L ) /* L, s */
avxins (DIVSD,    vdivsd,        P_AVX, 0 )    /* -, s */
avxins (DIVSS,    vdivss,        P_AVX, 0 )    /* -, s */
avxins (MAXPD,    vmaxpd,        P_AVX, VX_L ) /* L, s */
avxins (MAXPS,    vmaxps,        P_AVX, VX_L ) /* L, s */
avxins (MAXSD,    vmaxsd,        P_AVX, 0 )    /* -, s */
avxins (MAXSS,    vmaxss,        P_AVX, 0 )    /* -, s */
avxins (MINPD,    vminpd,        P_AVX, VX_L ) /* L, s */
avxins (MINPS,    vminps,        P_AVX, VX_L ) /* L, s */
avxins (MINSD,    vminsd,        P_AVX, 0 )    /* -, s */
avxins (MINSS,    vminss,        P_AVX, 0 )    /* -, s */
avxins (MULPD,    vmulpd,        P_AVX, VX_L ) /* L, s */
avxins (MULPS,    vmulps,        P_AVX, VX_L ) /* L, s */
avxins (MULSD,    vmulsd,        P_AVX, 0 )    /* -, s */
avxins (MULSS,    vmulss,        P_AVX, 0 )    /* -, s */
avxins (SQRTPD,   vsqrtpd,       P_AVX, VX_L ) /* L, s */
avxins (SQRTPS,   vsqrtps,       P_AVX, VX_L ) /* L, s */
avxins (SQRTSD,   vsqrtsd,       P_AVX, 0 )    /* -, s */
avxins (SQRTSS,   vsqrtss,       P_AVX, 0 )    /* -, s */
avxins (SUBPD,    vsubpd,        P_AVX, VX_L ) /* L, s */
avxins (SUBPS,    vsubps,        P_AVX, VX_L ) /* L, s */
avxins (SUBSD,    vsubsd,        P_AVX, 0 )    /* -, s */
avxins (SUBSS,    vsubss,        P_AVX, 0 )    /* -, s */
avxins (CMPPD,    vcmppd,        P_AVX, VX_L ) /* L, s */
avxins (CMPPS,    vcmpps,        P_AVX, VX_L ) /* L, s */
avxins (CMPSD,    vcmpsd,        P_AVX, 0 )    /* -, s */
avxins (CMPSS,    vcmpss,        P_AVX, 0 )    /* -, s */

/* format: xmm|ymm, xmm|ymm|mem */
avxins (ANDPD,    vandpd,        P_AVX, VX_L )   /* L, s */
avxins (ANDPS,    vandps,        P_AVX, VX_L )   /* L, s */
avxins (ANDNPD,   vandnpd,       P_AVX, VX_L )   /* L, s */
avxins (ANDNPS,   vandnps,       P_AVX, VX_L )   /* L, s */
avxins (ORPD,     vorpd,         P_AVX, VX_L )   /* L, s */
avxins (ORPS,     vorps,         P_AVX, VX_L )   /* L, s */
avxins (COMISD,   vcomisd,       P_AVX, VX_NND ) /* -, ns */
avxins (COMISS,   vcomiss,       P_AVX, VX_NND ) /* -, ns */
avxins (XORPD,    vxorpd,        P_AVX, VX_L )   /* L, s */
avxins (XORPS,    vxorps,        P_AVX, VX_L )   /* L, s */

/* format: xmm|ymm, xmm|ymm|mem */
avxins (CVTDQ2PD, vcvtdq2pd,     P_AVX, VX_L|VX_NND|VX_HALF ) /* L, ns, 64->128 */
avxins (CVTDQ2PS, vcvtdq2ps,     P_AVX, VX_L|VX_NND ) /* L, ns */
//avxins (CVTPD2DQ, vcvtpd2dq,     P_AVX, VX_L|VX_NND ) /* L, ns */
//avxins (CVTTPD2DQ,vcvttpd2dq,    P_AVX, VX_L|VX_NND ) /* L, ns */
//avxins (CVTPD2PS, vcvtpd2ps,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (CVTPS2DQ, vcvtps2dq,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (CVTTPS2DQ,vcvttps2dq,    P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (CVTPS2PD, vcvtps2pd,     P_AVX, VX_L|VX_NND|VX_HALF ) /* L, ns, 64->128 */
avxins (CVTSD2SI, vcvtsd2si,     P_AVX, VX_NND )   /* -, ns, W */
avxins (CVTTSD2SI,vcvttsd2si,    P_AVX, VX_NND )   /* -, ns, W */
avxins (CVTSD2SS, vcvtsd2ss,     P_AVX, 0 )        /* -, s     */
avxins (CVTSI2SD, vcvtsi2sd,     P_AVX, 0 )        /* -, s,  W */
avxins (CVTSI2SS, vcvtsi2ss,     P_AVX, 0 )        /* -, s,  W */
avxins (CVTSS2SD, vcvtss2sd,     P_AVX, 0 )        /* -, s     */
avxins (CVTSS2SI, vcvtss2si,     P_AVX, VX_NND )   /* -, ns, W */
avxins (CVTTSS2SI,vcvttss2si,    P_AVX, VX_NND )   /* -, ns, W */

/* format: xmm|ymm, xmm|ymm|mem [, i8] */
avxins (ADDSUBPD, vaddsubpd,     P_AVX, VX_L )     /* L, s */
avxins (ADDSUBPS, vaddsubps,     P_AVX, VX_L )     /* L, s */
avxins (BLENDPD , vblendpd ,     P_AVX, VX_L )     /* L, s */
avxins (BLENDPS , vblendps ,     P_AVX, VX_L )     /* L, s */
avxins (DPPD    , vdppd    ,     P_AVX, 0 )        /* -, s */
avxins (DPPS    , vdpps    ,     P_AVX, VX_L )     /* L, s */
avxins (EXTRACTPS,vextractps,    P_AVX, VX_NND )   /* -, ns! */ /* format: reg|mem32, xmm|ymm, i8 */
avxins (HADDPD  , vhaddpd  ,     P_AVX, VX_L )     /* L, s */
avxins (HADDPS  , vhaddps  ,     P_AVX, VX_L )     /* L, s */
avxins (HSUBPD  , vhsubpd  ,     P_AVX, VX_L )     /* L, s */
avxins (HSUBPS  , vhsubps  ,     P_AVX, VX_L )     /* L, s */
avxins (INSERTPS, vinsertps,     P_AVX, 0 )        /* -, s */
avxins (LDDQU   , vlddqu   ,     P_AVX, VX_L|VX_NND ) /* L, ns */ /* format: xmm|ymm, mem */
avxins (LDMXCSR , vldmxcsr ,     P_AVX, 0 )        /* -, ns */ /* format: mem32 */
avxins (STMXCSR , vstmxcsr ,     P_AVX, 0 )        /* -, ns */ /* format: mem32 */

avxins (MASKMOVDQU,vmaskmovdqu,  P_AVX, VX_NND )   /* -, ns */
avxins (MOVAPD  , vmovapd  ,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (MOVAPS  , vmovaps  ,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (MOVD    , vmovd    ,     P_AVX, VX_NND )   /* -, ns */
avxins (MOVQ    , vmovq    ,     P_AVX, VX_NND )   /* -, ns */
avxins (MOVDQA  , vmovdqa  ,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (MOVDQU  , vmovdqu  ,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (MOVHLPS , vmovhlps ,     P_AVX, 0 )        /* -, s */
avxins (MOVLHPS , vmovlhps ,     P_AVX, 0 )        /* -, s */
avxins (MOVHPD  , vmovhpd  ,     P_AVX, VX_NMEM )  /* -, s/ns! */
avxins (MOVHPS  , vmovhps  ,     P_AVX, VX_NMEM )  /* -, s/ns! */
avxins (MOVLPD  , vmovlpd  ,     P_AVX, VX_NMEM )  /* -, s/ns! */
avxins (MOVLPS  , vmovlps  ,     P_AVX, VX_NMEM )  /* -, s/ns! */
avxins (MOVSD   , vmovsd   ,     P_AVX, VX_NMEM )  /* -, s/ns! */ /* special case, see parser.c */
avxins (MOVSS   , vmovss   ,     P_AVX, VX_NMEM )  /* -, s/ns! */ /* special case, see parser.c */
/* v2.11: now handled in instruct.h */
//avxins (MOVMSKPD, vmovmskpd,     P_AVX, VX_L|VX_NND ) /* L, ns */
//avxins (MOVMSKPS, vmovmskps,     P_AVX, VX_L|VX_NND ) /* L, ns */
/* v2.11: VX_L flag added */
//avxins (MOVNTDQ , vmovntdq ,     P_AVX, VX_NND )   /* -, ns */
//avxins (MOVNTPD , vmovntpd ,     P_AVX, VX_NND )   /* -, ns */
//avxins (MOVNTPS , vmovntps ,     P_AVX, VX_NND )   /* -, ns */
avxins (MOVNTDQ , vmovntdq ,     P_AVX, VX_L|VX_NND )   /* L, ns */
avxins (MOVNTDQA, vmovntdqa,     P_AVX, VX_NND )     /* -, ns */
avxins (MOVNTPD , vmovntpd ,     P_AVX, VX_L|VX_NND )   /* L, ns */
avxins (MOVNTPS , vmovntps ,     P_AVX, VX_L|VX_NND )   /* L, ns */
avxins (MOVSHDUP, vmovshdup,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (MOVSLDUP, vmovsldup,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (MOVUPD  , vmovupd  ,     P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (MOVUPS  , vmovups  ,     P_AVX, VX_L|VX_NND ) /* L, ns */

avxins (MPSADBW , vmpsadbw ,     P_AVX, 0 )        /* -, s */

avxins (PABSB   , vpabsb   ,     P_AVX, VX_NND )   /* -, ns */
avxins (PABSW   , vpabsw   ,     P_AVX, VX_NND )   /* -, ns */
avxins (PABSD   , vpabsd   ,     P_AVX, VX_NND )   /* -, ns */
avxins (PACKSSWB, vpacksswb,     P_AVX, 0 )        /* -, s */
avxins (PACKSSDW, vpackssdw,     P_AVX, 0 )        /* -, s */
avxins (PACKUSWB, vpackuswb,     P_AVX, 0 )        /* -, s */
avxins (PACKUSDW, vpackusdw,     P_AVX, 0 )        /* -, s */
avxins (PADDB   , vpaddb   ,     P_AVX, 0 )        /* -, s */
avxins (PADDW   , vpaddw   ,     P_AVX, 0 )        /* -, s */
avxins (PADDD   , vpaddd   ,     P_AVX, 0 )        /* -, s */
avxins (PADDQ   , vpaddq   ,     P_AVX, 0 )        /* -, s */
avxins (PADDSB  , vpaddsb  ,     P_AVX, 0 )        /* -, s */
avxins (PADDSW  , vpaddsw  ,     P_AVX, 0 )        /* -, s */
avxins (PADDUSB , vpaddusb ,     P_AVX, 0 )        /* -, s */
avxins (PADDUSW , vpaddusw ,     P_AVX, 0 )        /* -, s */
avxins (PALIGNR , vpalignr ,     P_AVX, 0 )        /* -, s */
avxins (PAND    , vpand    ,     P_AVX, 0 )        /* -, s */
avxins (PANDN   , vpandn   ,     P_AVX, 0 )        /* -, s */
avxins (PAVGB   , vpavgb   ,     P_AVX, 0 )        /* -, s */
avxins (PAVGW   , vpavgw   ,     P_AVX, 0 )        /* -, s */
avxins (PBLENDW , vpblendw ,     P_AVX, 0 )        /* -, s */
avxins (PCMPESTRI,vpcmpestri,    P_AVX, VX_NND )   /* -, ns! */
avxins (PCMPESTRM,vpcmpestrm,    P_AVX, VX_NND )   /* -, ns! */
avxins (PCMPISTRI,vpcmpistri,    P_AVX, VX_NND )   /* -, ns! */
avxins (PCMPISTRM,vpcmpistrm,    P_AVX, VX_NND )   /* -, ns! */
avxins (PCMPEQB  ,vpcmpeqb  ,    P_AVX, 0 )        /* -, s */
avxins (PCMPEQW  ,vpcmpeqw  ,    P_AVX, 0 )        /* -, s */
avxins (PCMPEQD  ,vpcmpeqd  ,    P_AVX, 0 )        /* -, s */
avxins (PCMPEQQ  ,vpcmpeqq  ,    P_AVX, 0 )        /* -, s */
avxins (PCMPGTB  ,vpcmpgtB  ,    P_AVX, 0 )        /* -, s */
avxins (PCMPGTW  ,vpcmpgtw  ,    P_AVX, 0 )        /* -, s */
avxins (PCMPGTD  ,vpcmpgtd  ,    P_AVX, 0 )        /* -, s */
avxins (PCMPGTQ  ,vpcmpgtq  ,    P_AVX, 0 )        /* -, s */
avxins (PEXTRB   ,vpextrb   ,    P_AVX, VX_NND )   /* -, ns! */
avxins (PEXTRW   ,vpextrw   ,    P_AVX, VX_NND )   /* -, ns! */
avxins (PEXTRD   ,vpextrd   ,    P_AVX, VX_NND )   /* -, ns! */
avxins (PINSRB   ,vpinsrb   ,    P_AVX, 0 )        /* -, s */
avxins (PINSRW   ,vpinsrw   ,    P_AVX, 0 )        /* -, s */
avxins (PINSRD   ,vpinsrd   ,    P_AVX, 0 )        /* -, s */
#if AMD64_SUPPORT
avxins (PEXTRQ   ,vpextrq   ,    P_AVX, VX_NND )   /* -, ns! */
avxins (PINSRQ   ,vpinsrq   ,    P_AVX, 0 )        /* -, s */
#endif
avxins (PHADDW   ,vphaddw   ,    P_AVX, 0 )        /* -, s */
avxins (PHADDD   ,vphaddd   ,    P_AVX, 0 )        /* -, s */
avxins (PHADDSW  ,vphaddsw  ,    P_AVX, 0 )        /* -, s */
avxins (PHMINPOSUW,vphminposuw,  P_AVX, VX_NND )   /* -, ns */
avxins (PHSUBW   ,vphsubw   ,    P_AVX, 0 )        /* -, s */
avxins (PHSUBD   ,vphsubd   ,    P_AVX, 0 )        /* -, s */
avxins (PHSUBSW  ,vphsubsw  ,    P_AVX, 0 )        /* -, s */
avxins (PMADDWD  ,vpmaddwd  ,    P_AVX, 0 )        /* -, s */
avxins (PMADDUBSW,vpmaddubsw,    P_AVX, 0 )        /* -, s */
avxins (PMAXSB   ,vpmaxsb   ,    P_AVX, 0 )        /* -, s */
avxins (PMAXSW   ,vpmaxsw   ,    P_AVX, 0 )        /* -, s */
avxins (PMAXSD   ,vpmaxsd   ,    P_AVX, 0 )        /* -, s */
avxins (PMAXUB   ,vpmaxub   ,    P_AVX, 0 )        /* -, s */
avxins (PMAXUW   ,vpmaxuw   ,    P_AVX, 0 )        /* -, s */
avxins (PMAXUD   ,vpmaxud   ,    P_AVX, 0 )        /* -, s */
avxins (PMINSB   ,vpminsb   ,    P_AVX, 0 )        /* -, s */
avxins (PMINSW   ,vpminsw   ,    P_AVX, 0 )        /* -, s */
avxins (PMINSD   ,vpminsd   ,    P_AVX, 0 )        /* -, s */
avxins (PMINUB   ,vpminub   ,    P_AVX, 0 )        /* -, s */
avxins (PMINUW   ,vpminuw   ,    P_AVX, 0 )        /* -, s */
avxins (PMINUD   ,vpminud   ,    P_AVX, 0 )        /* -, s */
avxins (PMOVMSKB ,vpmovmskb ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVSXBW ,vpmovsxbw ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVSXBD ,vpmovsxbd ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVSXBQ ,vpmovsxbq ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVSXWD ,vpmovsxwd ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVSXWQ ,vpmovsxwq ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVSXDQ ,vpmovsxdq ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVZXBW ,vpmovzxbw ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVZXBD ,vpmovzxbd ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVZXBQ ,vpmovzxbq ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVZXWD ,vpmovzxwd ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVZXWQ ,vpmovzxwq ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMOVZXDQ ,vpmovzxdq ,    P_AVX, VX_NND )   /* -, ns */
avxins (PMULHUW  ,vpmulhuw  ,    P_AVX, 0 )        /* -, s */
avxins (PMULHRSW ,vpmulhrsw ,    P_AVX, 0 )        /* -, s */
avxins (PMULHW   ,vpmulhw   ,    P_AVX, 0 )        /* -, s */
avxins (PMULLW   ,vpmullw   ,    P_AVX, 0 )        /* -, s */
avxins (PMULLD   ,vpmulld   ,    P_AVX, 0 )        /* -, s */
avxins (PMULUDQ  ,vpmuludq  ,    P_AVX, 0 )        /* -, s */
avxins (PMULDQ   ,vpmuldq   ,    P_AVX, 0 )        /* -, s */
avxins (POR      ,vpor      ,    P_AVX, 0 )        /* -, s */
avxins (PSADBW   ,vpsadbw   ,    P_AVX, 0 )        /* -, s */
avxins (PSHUFB   ,vpshufb   ,    P_AVX, 0 )        /* -, s */
avxins (PSHUFD   ,vpshufd   ,    P_AVX, VX_NND )   /* -, ns! */
avxins (PSHUFHW  ,vpshufhw  ,    P_AVX, VX_NND )   /* -, ns! */
avxins (PSHUFLW  ,vpshuflw  ,    P_AVX, VX_NND )   /* -, ns! */
avxins (PSIGNB   ,vpsignb   ,    P_AVX, 0 )        /* -, s */
avxins (PSIGNW   ,vpsignw   ,    P_AVX, 0 )        /* -, s */
avxins (PSIGND   ,vpsignd   ,    P_AVX, 0 )        /* -, s */
avxins (PSLLDQ   ,vpslldq   ,    P_AVX, VX_DST )   /* -, d */
avxins (PSRLDQ   ,vpsrldq   ,    P_AVX, VX_DST )   /* -, d */
avxins (PSLLW    ,vpsllw    ,    P_AVX, VX_DST )   /* -, d/s */
avxins (PSLLD    ,vpslld    ,    P_AVX, VX_DST )   /* -, d/s */
avxins (PSLLQ    ,vpsllq    ,    P_AVX, VX_DST )   /* -, d/s */
avxins (PSRAW    ,vpsraw    ,    P_AVX, VX_DST )   /* -, d/s */
avxins (PSRAD    ,vpsrad    ,    P_AVX, VX_DST )   /* -, d/s */
avxins (PSRLW    ,vpsrlw    ,    P_AVX, VX_DST )   /* -, d/s */
avxins (PSRLD    ,vpsrld    ,    P_AVX, VX_DST )   /* -, d/s */
avxins (PSRLQ    ,vpsrlq    ,    P_AVX, VX_DST )   /* -, d/s */
/* */
avxins (PTEST    ,vptest    ,    P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (PSUBB    ,vpsubb    ,    P_AVX, 0 )        /* -, s */
avxins (PSUBW    ,vpsubw    ,    P_AVX, 0 )        /* -, s */
avxins (PSUBD    ,vpsubd    ,    P_AVX, 0 )        /* -, s */
avxins (PSUBQ    ,vpsubq    ,    P_AVX, 0 )        /* -, s */
avxins (PSUBSB   ,vpsubsb   ,    P_AVX, 0 )        /* -, s */
avxins (PSUBSW   ,vpsubsw   ,    P_AVX, 0 )        /* -, s */
avxins (PSUBUSB  ,vpsubusb  ,    P_AVX, 0 )        /* -, s */
avxins (PSUBUSW  ,vpsubusw  ,    P_AVX, 0 )        /* -, s */
avxins (PUNPCKHBW ,vpunpckhbw,   P_AVX, 0 )        /* -, s */
avxins (PUNPCKHWD ,vpunpckhwd,   P_AVX, 0 )        /* -, s */
avxins (PUNPCKHDQ ,vpunpckhdq,   P_AVX, 0 )        /* -, s */
avxins (PUNPCKHQDQ,vpunpckhqdq,  P_AVX, 0 )        /* -, s */
avxins (PUNPCKLBW ,vpunpcklbw,   P_AVX, 0 )        /* -, s */
avxins (PUNPCKLWD ,vpunpcklwd,   P_AVX, 0 )        /* -, s */
avxins (PUNPCKLDQ ,vpunpckldq,   P_AVX, 0 )        /* -, s */
avxins (PUNPCKLQDQ,vpunpcklqdq,  P_AVX, 0 )        /* -, s */
avxins (PXOR     ,vpxor     ,    P_AVX, 0 )        /* -, s */

avxins (RCPPS    ,vrcpps    ,    P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (RCPSS    ,vrcpss    ,    P_AVX, 0 )        /* -, s */
avxins (RSQRTPS  ,vrsqrtps  ,    P_AVX, VX_L|VX_NND ) /* L, ns */
avxins (RSQRTSS  ,vrsqrtss  ,    P_AVX, 0 )        /* -, s */
avxins (ROUNDPD  ,vroundpd  ,    P_AVX, VX_L|VX_NND ) /* L, ns! */
avxins (ROUNDPS  ,vroundps  ,    P_AVX, VX_L|VX_NND ) /* L, ns! */
avxins (ROUNDSD  ,vroundsd  ,    P_AVX, 0 )        /* -, s */
avxins (ROUNDSS  ,vroundss  ,    P_AVX, 0 )        /* -, s */
avxins (SHUFPD   ,vshufpd   ,    P_AVX, VX_L )     /* L, s */
avxins (SHUFPS   ,vshufps   ,    P_AVX, VX_L )     /* L, s */
avxins (UCOMISD  ,vucomisd  ,    P_AVX, VX_NND )   /* -, ns */
avxins (UCOMISS  ,vucomiss  ,    P_AVX, VX_NND )   /* -, ns */
avxins (UNPCKHPD ,vunpckhpd ,    P_AVX, VX_L )     /* L, s */
avxins (UNPCKHPS ,vunpckhps ,    P_AVX, VX_L )     /* L, s */
avxins (UNPCKLPD ,vunpcklpd ,    P_AVX, VX_L )     /* L, s */
avxins (UNPCKLPS ,vunpcklps ,    P_AVX, VX_L )     /* L, s */
#endif

//avxins (PCLMULQDQ,vpclmulqdq,    P_AVX, 0 )
