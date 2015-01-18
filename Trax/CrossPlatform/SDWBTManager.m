//
//  SDWBTManager.m
//  Trax
//
//  Created by alex on 1/17/15.
//  Copyright (c) 2015 SDWR. All rights reserved.
//
@import CoreBluetooth;
//@import MediaPlayer;


#import "SDWBTManager.h"
#import "SDWMusicManager.h"

@interface SDWBTManager () <CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>

@end

@implementation SDWBTManager

- (instancetype)init {

    self = [super init];
    if (self) {

        [self setup];
    }
    return self;
}

#pragma mark - Setup

- (void)setup {

    self.discoveredDevices = [NSMutableSet set];

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:queue];
}


#pragma mark - GATT Services

- (void)setupServices {}



#pragma mark - CBPeripheralManagerDelegate

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {

    if (!self.mainInfoService) {
        [self setupServices];
    }
}


- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {

    self.discoveredDevice = peripheral;
    [self.centralManager connectPeripheral:self.discoveredDevice options:nil];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

}
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self.centralManager scanForPeripheralsWithServices:nil options: @{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
            break;
        default:
            break;
    }


}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {

    NSLog(@"didDisconnectPeripheral");
    self.discoveredDevice = nil;
    [self.centralManager scanForPeripheralsWithServices:nil options: @{ CBCentralManagerScanOptionAllowDuplicatesKey : @NO}];
}



#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {

    for (CBCharacteristic *cr in service.characteristics) {

        NSLog(@"CBCharacteristic UUID - %@",cr.UUID);
        NSString *printable = [[NSString alloc] initWithData:cr.value encoding:NSUTF8StringEncoding];
        NSLog(@"CBCharacteristic value - %@", printable);

        if (cr.properties & CBCharacteristicPropertyNotify) {


            [self.discoveredDevice setNotifyValue:YES
                                forCharacteristic:cr];

        }


    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    [self.discoveredDevices addObject:peripheral];
    [self updateDeviceInfo];

}

- (void)updateDeviceInfo {}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {

    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    } else {
        // Notification has stopped
       // [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark - Utils 


- (void)sendValue:(id)value forCharacteristic:(CBMutableCharacteristic *)cr {

    NSData* data = [value dataUsingEncoding:NSUTF8StringEncoding];
    [self.peripheralManager updateValue:data forCharacteristic:cr onSubscribedCentrals:nil];
}


@end
