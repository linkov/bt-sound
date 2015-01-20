//
//  ViewController.m
//  TraxMac
//
//  Created by alex on 1/18/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//

#import "ViewController.h"
#import "SDWMusicBTManagerMac.h"

@interface ViewController () <SDWBTManagerDelegate>

@property SDWMusicBTManagerMac *btManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.btManager = [SDWMusicBTManagerMac new];
    self.btManager.delegate = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)managerDidPopulateData:(NSArray *)data {

  //  NSLog(@"mac received tracks - %@",data);
}

@end
