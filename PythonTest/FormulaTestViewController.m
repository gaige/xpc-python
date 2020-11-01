//
//  FormulaTestViewController.m
//  PythonTest
//
//  Created by Gaige B. Paulsen on 11/1/20. See accompanying LICENSE document.
//  Copyright 2020, ClueTrust.
//

#import "FormulaTestViewController.h"
#import "MapGeometry.h"
#import "MapGeometryExternalProxy.h"

@interface FormulaTestViewController ()
@property(strong) FormulaExecutorProxy *proxy;
@property(strong) MapGeometry *geometry;
@end

@implementation FormulaTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _proxy = [[FormulaExecutorProxy alloc] init];
    _geometry = [[MapGeometry alloc] initWithRect: CGRectMake(0, 0, 50, 20)];
}

- (IBAction)calculate:(id)sender
{
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    NSString *valueString = _aValue.stringValue;
    if (valueString)
        values[@"a"]=valueString;
    valueString = _bValue.stringValue;
    if (valueString.length>0)
        values[@"b"]=@([valueString doubleValue]);
    
    [_proxy validateFormula: _input.stringValue forEntity:[MapGeometryExternalProxy mapGeometryExternalProxyWithMapGeometry:_geometry] andInfo: values withReply:^(id result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result) {
                if ([result isKindOfClass:NSString.class])
                    self.output.stringValue = result;
                else if ([result isKindOfClass: NSDate.class])
                    self.output.stringValue = result;
                else
                    self.output.stringValue = [result stringValue];
            } else
                self.output.stringValue = [error localizedDescription];
        });
    }];
}
@end
