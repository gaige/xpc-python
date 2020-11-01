//
//  FormulaExecutor.m
//  FormulaExecutor
//
//  Created by Gaige B. Paulsen on 12/28/19. See accompanying LICENSE document.
//  Copyright 2019, ClueTrust.
//

#import "FormulaExecutor.h"

@implementation FormulaExecutor

PyComputation *gComputer=nil;
dispatch_queue_t gComputeQueue =nil;
+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gComputer = [[PyComputation alloc] init];
        NSError *error;
        if (![gComputer startInterpreter: &error]) {
            NSLog(@"Error starting interpreter %@", error);
        }
        gComputeQueue = dispatch_queue_create("Python queue", NULL);

    });
}

- (void)validateFormula:(NSString *)safeFormula forEntity:(id<MapGeometryExternalProtocol>)geometry andInfo:(NSDictionary<NSString *,id> *)infoDictionary withReply:(void (^)(id, NSError *))reply
{
    dispatch_async( gComputeQueue, ^{
        id result = nil;
        NSError *error=nil;
        
        gComputer.formula = safeFormula;
        if ([gComputer compileCode: &error]) {
            if (geometry)
                [gComputer setLibraryValue: geometry forKey:@"geometry"];

            result = [gComputer calculateForInfo: infoDictionary withError: &error];
            if (result)
                error=nil;
        }
#ifdef LOG_LOCALLY
        NSLog(@"formula = '%@', result='%@'", safeFormula, result);
        if (error)
            NSLog(@"Error = %@", error);
#endif // LOG_LOCALLY
        reply(result, error);
    });
}

@end
