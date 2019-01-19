; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s  -loop-vectorize -force-vector-interleave=1 -force-vector-width=4 -dce -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; PR15794
; incorrect addition of llvm.mem.parallel_loop_access metadata is undefined
; behaviour. Vectorizer ignores the memory dependency checks and goes ahead and
; vectorizes this loop with uniform stores which has an output dependency.

; void foo(int *a, int *b, int k, int m) {
;   for (int i = 0; i < m; i++) {
;     for (int j = 0; j < m; j++) {
;       a[i] = a[i + j + k] + 1; <<<
;     }
;     b[i] = b[i] + 3;
;   }
; }

; Function Attrs: nounwind uwtable
define void @foo(i32* nocapture %a, i32* nocapture %b, i32 %k, i32 %m) #0 {
; CHECK-LABEL: @foo(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP27:%.*]] = icmp sgt i32 [[M:%.*]], 0
; CHECK-NEXT:    br i1 [[CMP27]], label [[FOR_BODY3_LR_PH_US_PREHEADER:%.*]], label [[FOR_END15:%.*]]
; CHECK:       for.body3.lr.ph.us.preheader:
; CHECK-NEXT:    [[TMP0:%.*]] = add i32 [[M]], -1
; CHECK-NEXT:    [[TMP1:%.*]] = zext i32 [[TMP0]] to i64
; CHECK-NEXT:    [[TMP2:%.*]] = add i64 [[TMP1]], 1
; CHECK-NEXT:    [[TMP3:%.*]] = zext i32 [[K:%.*]] to i64
; CHECK-NEXT:    br label [[FOR_BODY3_LR_PH_US:%.*]]
; CHECK:       for.end.us:
; CHECK-NEXT:    [[ARRAYIDX9_US:%.*]] = getelementptr inbounds i32, i32* [[B:%.*]], i64 [[INDVARS_IV33:%.*]]
; CHECK-NEXT:    [[TMP4:%.*]] = load i32, i32* [[ARRAYIDX9_US]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[ADD10_US:%.*]] = add nsw i32 [[TMP4]], 3
; CHECK-NEXT:    store i32 [[ADD10_US]], i32* [[ARRAYIDX9_US]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[INDVARS_IV_NEXT34:%.*]] = add i64 [[INDVARS_IV33]], 1
; CHECK-NEXT:    [[LFTR_WIDEIV35:%.*]] = trunc i64 [[INDVARS_IV_NEXT34]] to i32
; CHECK-NEXT:    [[EXITCOND36:%.*]] = icmp eq i32 [[LFTR_WIDEIV35]], [[M]]
; CHECK-NEXT:    br i1 [[EXITCOND36]], label [[FOR_END15_LOOPEXIT:%.*]], label [[FOR_BODY3_LR_PH_US]], !llvm.loop !2
; CHECK:       for.body3.us:
; CHECK-NEXT:    [[INDVARS_IV29:%.*]] = phi i64 [ [[BC_RESUME_VAL:%.*]], [[SCALAR_PH:%.*]] ], [ [[INDVARS_IV_NEXT30:%.*]], [[FOR_BODY3_US:%.*]] ]
; CHECK-NEXT:    [[TMP5:%.*]] = trunc i64 [[INDVARS_IV29]] to i32
; CHECK-NEXT:    [[ADD4_US:%.*]] = add i32 [[ADD_US:%.*]], [[TMP5]]
; CHECK-NEXT:    [[IDXPROM_US:%.*]] = sext i32 [[ADD4_US]] to i64
; CHECK-NEXT:    [[ARRAYIDX_US:%.*]] = getelementptr inbounds i32, i32* [[A:%.*]], i64 [[IDXPROM_US]]
; CHECK-NEXT:    [[TMP6:%.*]] = load i32, i32* [[ARRAYIDX_US]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[ADD5_US:%.*]] = add nsw i32 [[TMP6]], 1
; CHECK-NEXT:    store i32 [[ADD5_US]], i32* [[ARRAYIDX7_US:%.*]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[INDVARS_IV_NEXT30]] = add i64 [[INDVARS_IV29]], 1
; CHECK-NEXT:    [[LFTR_WIDEIV31:%.*]] = trunc i64 [[INDVARS_IV_NEXT30]] to i32
; CHECK-NEXT:    [[EXITCOND32:%.*]] = icmp eq i32 [[LFTR_WIDEIV31]], [[M]]
; CHECK-NEXT:    br i1 [[EXITCOND32]], label [[FOR_END_US:%.*]], label [[FOR_BODY3_US]], !llvm.loop !3
; CHECK:       for.body3.lr.ph.us:
; CHECK-NEXT:    [[INDVARS_IV33]] = phi i64 [ [[INDVARS_IV_NEXT34]], [[FOR_END_US]] ], [ 0, [[FOR_BODY3_LR_PH_US_PREHEADER]] ]
; CHECK-NEXT:    [[TMP7:%.*]] = add i64 [[TMP3]], [[INDVARS_IV33]]
; CHECK-NEXT:    [[TMP8:%.*]] = trunc i64 [[TMP7]] to i32
; CHECK-NEXT:    [[TMP9:%.*]] = trunc i64 [[INDVARS_IV33]] to i32
; CHECK-NEXT:    [[ADD_US]] = add i32 [[TMP9]], [[K]]
; CHECK-NEXT:    [[ARRAYIDX7_US]] = getelementptr inbounds i32, i32* [[A]], i64 [[INDVARS_IV33]]
; CHECK-NEXT:    [[MIN_ITERS_CHECK:%.*]] = icmp ult i64 [[TMP2]], 4
; CHECK-NEXT:    br i1 [[MIN_ITERS_CHECK]], label [[SCALAR_PH]], label [[VECTOR_SCEVCHECK:%.*]]
; CHECK:       vector.scevcheck:
; CHECK-NEXT:    [[MUL:%.*]] = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 1, i32 [[TMP0]])
; CHECK-NEXT:    [[MUL_RESULT:%.*]] = extractvalue { i32, i1 } [[MUL]], 0
; CHECK-NEXT:    [[MUL_OVERFLOW:%.*]] = extractvalue { i32, i1 } [[MUL]], 1
; CHECK-NEXT:    [[TMP10:%.*]] = add i32 [[TMP8]], [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP11:%.*]] = sub i32 [[TMP8]], [[MUL_RESULT]]
; CHECK-NEXT:    [[TMP12:%.*]] = icmp sgt i32 [[TMP11]], [[TMP8]]
; CHECK-NEXT:    [[TMP13:%.*]] = icmp slt i32 [[TMP10]], [[TMP8]]
; CHECK-NEXT:    [[TMP14:%.*]] = select i1 false, i1 [[TMP12]], i1 [[TMP13]]
; CHECK-NEXT:    [[TMP15:%.*]] = or i1 [[TMP14]], [[MUL_OVERFLOW]]
; CHECK-NEXT:    [[TMP16:%.*]] = or i1 false, [[TMP15]]
; CHECK-NEXT:    br i1 [[TMP16]], label [[SCALAR_PH]], label [[VECTOR_PH:%.*]]
; CHECK:       vector.ph:
; CHECK-NEXT:    [[N_MOD_VF:%.*]] = urem i64 [[TMP2]], 4
; CHECK-NEXT:    [[N_VEC:%.*]] = sub i64 [[TMP2]], [[N_MOD_VF]]
; CHECK-NEXT:    br label [[VECTOR_BODY:%.*]]
; CHECK:       vector.body:
; CHECK-NEXT:    [[INDEX:%.*]] = phi i64 [ 0, [[VECTOR_PH]] ], [ [[INDEX_NEXT:%.*]], [[VECTOR_BODY]] ]
; CHECK-NEXT:    [[TMP17:%.*]] = trunc i64 [[INDEX]] to i32
; CHECK-NEXT:    [[TMP18:%.*]] = add i32 [[TMP17]], 0
; CHECK-NEXT:    [[TMP19:%.*]] = add i32 [[ADD_US]], [[TMP18]]
; CHECK-NEXT:    [[TMP20:%.*]] = sext i32 [[TMP19]] to i64
; CHECK-NEXT:    [[TMP21:%.*]] = getelementptr inbounds i32, i32* [[A]], i64 [[TMP20]]
; CHECK-NEXT:    [[TMP22:%.*]] = getelementptr inbounds i32, i32* [[TMP21]], i32 0
; CHECK-NEXT:    [[TMP23:%.*]] = bitcast i32* [[TMP22]] to <4 x i32>*
; CHECK-NEXT:    [[WIDE_LOAD:%.*]] = load <4 x i32>, <4 x i32>* [[TMP23]], align 4
; CHECK-NEXT:    [[TMP24:%.*]] = add nsw <4 x i32> [[WIDE_LOAD]], <i32 1, i32 1, i32 1, i32 1>
; CHECK-NEXT:    [[TMP25:%.*]] = extractelement <4 x i32> [[TMP24]], i32 0
; CHECK-NEXT:    store i32 [[TMP25]], i32* [[ARRAYIDX7_US]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[TMP26:%.*]] = extractelement <4 x i32> [[TMP24]], i32 1
; CHECK-NEXT:    store i32 [[TMP26]], i32* [[ARRAYIDX7_US]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[TMP27:%.*]] = extractelement <4 x i32> [[TMP24]], i32 2
; CHECK-NEXT:    store i32 [[TMP27]], i32* [[ARRAYIDX7_US]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[TMP28:%.*]] = extractelement <4 x i32> [[TMP24]], i32 3
; CHECK-NEXT:    store i32 [[TMP28]], i32* [[ARRAYIDX7_US]], align 4, !llvm.mem.parallel_loop_access !0
; CHECK-NEXT:    [[INDEX_NEXT]] = add i64 [[INDEX]], 4
; CHECK-NEXT:    [[TMP29:%.*]] = icmp eq i64 [[INDEX_NEXT]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[TMP29]], label [[MIDDLE_BLOCK:%.*]], label [[VECTOR_BODY]], !llvm.loop !5
; CHECK:       middle.block:
; CHECK-NEXT:    [[CMP_N:%.*]] = icmp eq i64 [[TMP2]], [[N_VEC]]
; CHECK-NEXT:    br i1 [[CMP_N]], label [[FOR_END_US]], label [[SCALAR_PH]]
; CHECK:       scalar.ph:
; CHECK-NEXT:    [[BC_RESUME_VAL]] = phi i64 [ [[N_VEC]], [[MIDDLE_BLOCK]] ], [ 0, [[FOR_BODY3_LR_PH_US]] ], [ 0, [[VECTOR_SCEVCHECK]] ]
; CHECK-NEXT:    br label [[FOR_BODY3_US]]
; CHECK:       for.end15.loopexit:
; CHECK-NEXT:    br label [[FOR_END15]]
; CHECK:       for.end15:
; CHECK-NEXT:    ret void
;
entry:
  %cmp27 = icmp sgt i32 %m, 0
  br i1 %cmp27, label %for.body3.lr.ph.us, label %for.end15

for.end.us:                                       ; preds = %for.body3.us
  %arrayidx9.us = getelementptr inbounds i32, i32* %b, i64 %indvars.iv33
  %0 = load i32, i32* %arrayidx9.us, align 4, !llvm.mem.parallel_loop_access !3
  %add10.us = add nsw i32 %0, 3
  store i32 %add10.us, i32* %arrayidx9.us, align 4, !llvm.mem.parallel_loop_access !3
  %indvars.iv.next34 = add i64 %indvars.iv33, 1
  %lftr.wideiv35 = trunc i64 %indvars.iv.next34 to i32
  %exitcond36 = icmp eq i32 %lftr.wideiv35, %m
  br i1 %exitcond36, label %for.end15, label %for.body3.lr.ph.us, !llvm.loop !5

for.body3.us:                                     ; preds = %for.body3.us, %for.body3.lr.ph.us
  %indvars.iv29 = phi i64 [ 0, %for.body3.lr.ph.us ], [ %indvars.iv.next30, %for.body3.us ]
  %1 = trunc i64 %indvars.iv29 to i32
  %add4.us = add i32 %add.us, %1
  %idxprom.us = sext i32 %add4.us to i64
  %arrayidx.us = getelementptr inbounds i32, i32* %a, i64 %idxprom.us
  %2 = load i32, i32* %arrayidx.us, align 4, !llvm.mem.parallel_loop_access !3
  %add5.us = add nsw i32 %2, 1
  store i32 %add5.us, i32* %arrayidx7.us, align 4, !llvm.mem.parallel_loop_access !3
  %indvars.iv.next30 = add i64 %indvars.iv29, 1
  %lftr.wideiv31 = trunc i64 %indvars.iv.next30 to i32
  %exitcond32 = icmp eq i32 %lftr.wideiv31, %m
  br i1 %exitcond32, label %for.end.us, label %for.body3.us, !llvm.loop !4

for.body3.lr.ph.us:                               ; preds = %for.end.us, %entry
  %indvars.iv33 = phi i64 [ %indvars.iv.next34, %for.end.us ], [ 0, %entry ]
  %3 = trunc i64 %indvars.iv33 to i32
  %add.us = add i32 %3, %k
  %arrayidx7.us = getelementptr inbounds i32, i32* %a, i64 %indvars.iv33
  br label %for.body3.us

for.end15:                                        ; preds = %for.end.us, %entry
  ret void
}

; Same test as above, but without the invalid parallel_loop_access metadata.

; Here we can see the vectorizer does the mem dep checks and decides it is
; unsafe to vectorize.
define void @no-par-mem-metadata(i32* nocapture %a, i32* nocapture %b, i32 %k, i32 %m) #0 {
; CHECK-LABEL: @no-par-mem-metadata(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP27:%.*]] = icmp sgt i32 [[M:%.*]], 0
; CHECK-NEXT:    br i1 [[CMP27]], label [[FOR_BODY3_LR_PH_US_PREHEADER:%.*]], label [[FOR_END15:%.*]]
; CHECK:       for.body3.lr.ph.us.preheader:
; CHECK-NEXT:    br label [[FOR_BODY3_LR_PH_US:%.*]]
; CHECK:       for.end.us:
; CHECK-NEXT:    [[ARRAYIDX9_US:%.*]] = getelementptr inbounds i32, i32* [[B:%.*]], i64 [[INDVARS_IV33:%.*]]
; CHECK-NEXT:    [[TMP0:%.*]] = load i32, i32* [[ARRAYIDX9_US]], align 4
; CHECK-NEXT:    [[ADD10_US:%.*]] = add nsw i32 [[TMP0]], 3
; CHECK-NEXT:    store i32 [[ADD10_US]], i32* [[ARRAYIDX9_US]], align 4
; CHECK-NEXT:    [[INDVARS_IV_NEXT34:%.*]] = add i64 [[INDVARS_IV33]], 1
; CHECK-NEXT:    [[LFTR_WIDEIV35:%.*]] = trunc i64 [[INDVARS_IV_NEXT34]] to i32
; CHECK-NEXT:    [[EXITCOND36:%.*]] = icmp eq i32 [[LFTR_WIDEIV35]], [[M]]
; CHECK-NEXT:    br i1 [[EXITCOND36]], label [[FOR_END15_LOOPEXIT:%.*]], label [[FOR_BODY3_LR_PH_US]], !llvm.loop !2
; CHECK:       for.body3.us:
; CHECK-NEXT:    [[INDVARS_IV29:%.*]] = phi i64 [ 0, [[FOR_BODY3_LR_PH_US]] ], [ [[INDVARS_IV_NEXT30:%.*]], [[FOR_BODY3_US:%.*]] ]
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i64 [[INDVARS_IV29]] to i32
; CHECK-NEXT:    [[ADD4_US:%.*]] = add i32 [[ADD_US:%.*]], [[TMP1]]
; CHECK-NEXT:    [[IDXPROM_US:%.*]] = sext i32 [[ADD4_US]] to i64
; CHECK-NEXT:    [[ARRAYIDX_US:%.*]] = getelementptr inbounds i32, i32* [[A:%.*]], i64 [[IDXPROM_US]]
; CHECK-NEXT:    [[TMP2:%.*]] = load i32, i32* [[ARRAYIDX_US]], align 4
; CHECK-NEXT:    [[ADD5_US:%.*]] = add nsw i32 [[TMP2]], 1
; CHECK-NEXT:    store i32 [[ADD5_US]], i32* [[ARRAYIDX7_US:%.*]], align 4
; CHECK-NEXT:    [[INDVARS_IV_NEXT30]] = add i64 [[INDVARS_IV29]], 1
; CHECK-NEXT:    [[LFTR_WIDEIV31:%.*]] = trunc i64 [[INDVARS_IV_NEXT30]] to i32
; CHECK-NEXT:    [[EXITCOND32:%.*]] = icmp eq i32 [[LFTR_WIDEIV31]], [[M]]
; CHECK-NEXT:    br i1 [[EXITCOND32]], label [[FOR_END_US:%.*]], label [[FOR_BODY3_US]], !llvm.loop !1
; CHECK:       for.body3.lr.ph.us:
; CHECK-NEXT:    [[INDVARS_IV33]] = phi i64 [ [[INDVARS_IV_NEXT34]], [[FOR_END_US]] ], [ 0, [[FOR_BODY3_LR_PH_US_PREHEADER]] ]
; CHECK-NEXT:    [[TMP3:%.*]] = trunc i64 [[INDVARS_IV33]] to i32
; CHECK-NEXT:    [[ADD_US]] = add i32 [[TMP3]], [[K:%.*]]
; CHECK-NEXT:    [[ARRAYIDX7_US]] = getelementptr inbounds i32, i32* [[A]], i64 [[INDVARS_IV33]]
; CHECK-NEXT:    br label [[FOR_BODY3_US]]
; CHECK:       for.end15.loopexit:
; CHECK-NEXT:    br label [[FOR_END15]]
; CHECK:       for.end15:
; CHECK-NEXT:    ret void
;
entry:
  %cmp27 = icmp sgt i32 %m, 0
  br i1 %cmp27, label %for.body3.lr.ph.us, label %for.end15

for.end.us:                                       ; preds = %for.body3.us
  %arrayidx9.us = getelementptr inbounds i32, i32* %b, i64 %indvars.iv33
  %0 = load i32, i32* %arrayidx9.us, align 4
  %add10.us = add nsw i32 %0, 3
  store i32 %add10.us, i32* %arrayidx9.us, align 4
  %indvars.iv.next34 = add i64 %indvars.iv33, 1
  %lftr.wideiv35 = trunc i64 %indvars.iv.next34 to i32
  %exitcond36 = icmp eq i32 %lftr.wideiv35, %m
  br i1 %exitcond36, label %for.end15, label %for.body3.lr.ph.us, !llvm.loop !5

for.body3.us:                                     ; preds = %for.body3.us, %for.body3.lr.ph.us
  %indvars.iv29 = phi i64 [ 0, %for.body3.lr.ph.us ], [ %indvars.iv.next30, %for.body3.us ]
  %1 = trunc i64 %indvars.iv29 to i32
  %add4.us = add i32 %add.us, %1
  %idxprom.us = sext i32 %add4.us to i64
  %arrayidx.us = getelementptr inbounds i32, i32* %a, i64 %idxprom.us
  %2 = load i32, i32* %arrayidx.us, align 4
  %add5.us = add nsw i32 %2, 1
  store i32 %add5.us, i32* %arrayidx7.us, align 4
  %indvars.iv.next30 = add i64 %indvars.iv29, 1
  %lftr.wideiv31 = trunc i64 %indvars.iv.next30 to i32
  %exitcond32 = icmp eq i32 %lftr.wideiv31, %m
  br i1 %exitcond32, label %for.end.us, label %for.body3.us, !llvm.loop !4

for.body3.lr.ph.us:                               ; preds = %for.end.us, %entry
  %indvars.iv33 = phi i64 [ %indvars.iv.next34, %for.end.us ], [ 0, %entry ]
  %3 = trunc i64 %indvars.iv33 to i32
  %add.us = add i32 %3, %k
  %arrayidx7.us = getelementptr inbounds i32, i32* %a, i64 %indvars.iv33
  br label %for.body3.us

for.end15:                                        ; preds = %for.end.us, %entry
  ret void
}

attributes #0 = { nounwind uwtable "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-frame-pointer-elim-non-leaf"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }

!3 = !{!4, !5}
!4 = !{!4}
!5 = !{!5}

