//
//  FormulaTestViewController.h
//  PythonTest
//
//  Created by Gaige B. Paulsen on 11/1/20. See accompanying LICENSE document.
//  Copyright 2020, ClueTrust.
//

#import <Cocoa/Cocoa.h>
#import "FormulaExecutorProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface FormulaTestViewController : NSViewController
@property(retain) IBOutlet NSTextField *input;
@property(retain) IBOutlet NSTextField *output;
@property(retain) IBOutlet NSTextField *aValue;
@property(retain) IBOutlet NSTextField *bValue;

@end

NS_ASSUME_NONNULL_END
