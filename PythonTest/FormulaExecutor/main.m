//
//  main.m
//  FormulaExecutor
//
//  Created by Gaige B. Paulsen on 12/28/19.
//

#import <Foundation/Foundation.h>
#import "FormulaExecutor.h"

@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation ServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    
    // Configure the connection.
    // First, set the interface that the exported object implements.
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FormulaExecutorProtocol)];
    
    NSXPCInterface *proxyGeometryInterface = [NSXPCInterface interfaceWithProtocol: @protocol(MapGeometryExternalProtocol)];
    [newConnection.exportedInterface
         setInterface: proxyGeometryInterface
          forSelector: @selector(validateFormula:forEntity:andInfo:withReply:)
        argumentIndex: 1  // the second parameter of
              ofReply: NO // the feedSomeone: method
    ];

    // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
    FormulaExecutor *exportedObject = [FormulaExecutor new];
    newConnection.exportedObject = exportedObject;
    
    // set up our ability to talk back to the code on the other side for proxy objects:
    
    // Resuming the connection allows the system to deliver more incoming messages.
    [newConnection resume];
    
    // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
    return YES;
}

@end

int main(int argc, const char *argv[])
{
    // Create the delegate for the service.
    ServiceDelegate *delegate = [ServiceDelegate new];
    
    // Set up the one NSXPCListener for this service. It will handle all incoming connections.
    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;
    
    // Resuming the serviceListener starts this service. This method does not return.
    [listener resume];
    return 0;
}
