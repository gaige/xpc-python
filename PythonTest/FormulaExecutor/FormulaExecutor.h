//
//  FormulaExecutor.h
//  FormulaExecutor
//
//  Created by Gaige B. Paulsen on 12/28/19.
//

#import <Foundation/Foundation.h>
#import "FormulaExecutorProtocol.h"
#import <Python/Python.h>

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface FormulaExecutor : NSObject <FormulaExecutorProtocol>
@end
