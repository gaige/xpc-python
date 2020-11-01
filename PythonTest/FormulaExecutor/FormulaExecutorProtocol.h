//
//  FormulaExecutorProtocol.h
//  FormulaExecutor
//
//  Created by Gaige B. Paulsen on 12/28/19.
//

#import <Foundation/Foundation.h>
#import "MapGeometryExternalProtocol.h"
#import "PyUtilities.h"
#import "PyComputation.h"
#import "PyGeometryModule.h"

// The protocol that this service will vend as its API. This header file will also need to be visible to the process hosting the service.
@protocol FormulaExecutorProtocol

- (void)validateFormula:(NSString*)safeFormula forEntity:(id<MapGeometryExternalProtocol>)entity andInfo:(NSDictionary<NSString*,id>*)infoDictionary withReply:(void (^)(id result, NSError*))reply;
@end

/*
 To use the service from an application or other process, use NSXPCConnection to establish a connection to the service by doing something like this:

     _connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"com.ClueTrust.FormulaExecutor"];
     _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FormulaExecutorProtocol)];
     [_connectionToService resume];

Once you have a connection to the service, you can use it like this:

     [[_connectionToService remoteObjectProxy] upperCaseString:@"hello" withReply:^(NSString *aString) {
         // We have received a response. Update our text field, but do it on the main thread.
         NSLog(@"Result string was: %@", aString);
     }];

 And, when you are finished with the service, clean up the connection like this:

     [_connectionToService invalidate];
*/
