//
//  ViewController.m
//  ExtendedReachability
//
//  Created by Goppinath Thurairajah on 03.05.15.
//  Copyright (c) 2015 Goppinath Thurairajah. All rights reserved.
//

#import "ViewController.h"

#import "ExtendedReachability.h"

@interface ViewController ()

@end

@implementation ViewController  {
    
    ExtendedReachability *googleReachability_;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    googleReachability_ = [ExtendedReachability reachabilityForInternetConnection];
    
    [googleReachability_ startNotifierWithReachabilityDidChangeHandler:^(ExtendedReachability *changedReachability) {
        
        NSLog(@"%d", [changedReachability currentReachabilityStatus]);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
