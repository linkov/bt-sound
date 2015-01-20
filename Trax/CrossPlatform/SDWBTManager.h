//
//  SDWBTManager.h
//  Trax
//
//  Created by alex on 1/17/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//
@import CoreBluetooth;
#import <Foundation/Foundation.h>

@protocol SDWBTManagerDelegate

@optional

- (void)managerDidPopulateData:(NSArray *)data;


@end


@interface SDWBTManager : NSObject


@property (weak) id<SDWBTManagerDelegate> delegate;


/* should be private for subclasses */

- (NSArray *)publish;
- (NSArray *)subscribe;
- (void)didUpdateCharacteristicValue;
- (void)setup;

- (void)sendValue:(id)value forCharacteristic:(CBMutableCharacteristic *)cr;

// PeripheralManager
@property CBPeripheralManager *peripheralManager;
@property NSMutableDictionary *peripheralData;

@property (strong) NSUUID *uid;

// Central manager
@property CBCentralManager *centralManager;
@property (strong) CBPeripheral *discoveredDevice;
@property (strong) NSMutableSet *discoveredDevices;

@property (strong) CBMutableService *mainInfoService;


@end
