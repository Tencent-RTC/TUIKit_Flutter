
#import "AtomicEngineSymbolDummy.h"
#import "atomic_engine_c_api.h"

@implementation AtomicEngineSymbolDummy

+ (void)atomicEngineRetainDartSymbols {
  AtomicEngine_Create();
}

@end
