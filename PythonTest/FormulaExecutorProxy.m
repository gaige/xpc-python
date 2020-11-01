//
//  FormulaExecutorProxy.m
//  MapClueCD
//
//  Created by Gaige B. Paulsen on 12/30/19. See accompanying LICENSE document.
//  Copyright 2019, ClueTrust.
//

#import "FormulaExecutorProxy.h"

@implementation FormulaExecutorProxy
- (instancetype)init
{
    self = [super init];
    if (self) {
        _connectionToService = [[NSXPCConnection alloc] initWithServiceName:@"com.ClueTrust.Example.FormulaExecutor"];
        _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FormulaExecutorProtocol)];
        [_connectionToService resume];
        
        NSXPCInterface *proxyGeometryInterface = [NSXPCInterface interfaceWithProtocol: @protocol(MapGeometryExternalProtocol)];
        [_connectionToService.remoteObjectInterface
             setInterface: proxyGeometryInterface
              forSelector: @selector(validateFormula:forEntity:andInfo:withReply:)
            argumentIndex: 1  // the second parameter of
                  ofReply: NO // the feedSomeone: method
        ];

    }
    return self;
}

-(void)dealloc
{
    [_connectionToService invalidate];
}

- (void)validateFormula:(NSString*)safeFormula forEntity:(id<MapGeometryExternalProtocol>)entity andInfo:(NSDictionary<NSString*,id>*)infoDictionary withReply:(void (^)(id result, NSError*))reply
{
    [_connectionToService.remoteObjectProxy validateFormula:safeFormula forEntity:entity andInfo:infoDictionary withReply:reply];
}

@end
