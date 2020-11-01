//
//  FormulaExecutorProxy.h
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 12/30/19.  See accompanying LICENSE document.
//  Copyright 2019, ClueTrust.
//

#import <Foundation/Foundation.h>
#import "FormulaExecutorProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface FormulaExecutorProxy : NSObject<FormulaExecutorProtocol>
@property (strong) NSXPCConnection *connectionToService;
@end

NS_ASSUME_NONNULL_END
