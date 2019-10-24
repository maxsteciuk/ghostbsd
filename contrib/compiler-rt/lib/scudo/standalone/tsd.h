//===-- tsd.h ---------------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef SCUDO_TSD_H_
#define SCUDO_TSD_H_

#include "atomic_helpers.h"
#include "common.h"
#include "mutex.h"

#include <limits.h> // for PTHREAD_DESTRUCTOR_ITERATIONS

// With some build setups, this might still not be defined.
#ifndef PTHREAD_DESTRUCTOR_ITERATIONS
#define PTHREAD_DESTRUCTOR_ITERATIONS 4
#endif

namespace scudo {

template <class Allocator> struct ALIGNED(SCUDO_CACHE_LINE_SIZE) TSD {
  typename Allocator::CacheT Cache;
  typename Allocator::QuarantineCacheT QuarantineCache;
  u8 DestructorIterations;

  void initLinkerInitialized(Allocator *Instance) {
    Instance->initCache(&Cache);
    DestructorIterations = PTHREAD_DESTRUCTOR_ITERATIONS;
  }
  void init(Allocator *Instance) {
    memset(this, 0, sizeof(*this));
    initLinkerInitialized(Instance);
  }

  void commitBack(Allocator *Instance) { Instance->commitBack(this); }

  INLINE bool tryLock() {
    if (Mutex.tryLock()) {
      atomic_store_relaxed(&Precedence, 0);
      return true;
    }
    if (atomic_load_relaxed(&Precedence) == 0)
      atomic_store_relaxed(
          &Precedence,
          static_cast<uptr>(getMonotonicTime() >> FIRST_32_SECOND_64(16, 0)));
    return false;
  }
  INLINE void lock() {
    atomic_store_relaxed(&Precedence, 0);
    Mutex.lock();
  }
  INLINE void unlock() { Mutex.unlock(); }
  INLINE uptr getPrecedence() { return atomic_load_relaxed(&Precedence); }

private:
  HybridMutex Mutex;
  atomic_uptr Precedence;
};

} // namespace scudo

#endif // SCUDO_TSD_H_
