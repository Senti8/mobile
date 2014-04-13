//
//  SENViewModel.m
//  sentiate
//
//  Created by Robert Carlsen on 4/12/14.
//  Copyright (c) 2014 Robert Carlsen. All rights reserved.
//

#import "SENViewModel.h"

/*
 Currently, only two commands.
 Emit scent.
 Selected scent.
*/

@interface SENViewModel ()
<BLEDelegate>
@end

NSString *const kScentTypeKey = @"kScentTypeKey";
NSString *const kScentLabelKey = @"kScentLabelKey";

@implementation SENViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _scentItems = @[
                        @{kScentLabelKey:@"Soil",
                          kScentTypeKey: @(SENScentTypeSoil) },
                        @{kScentLabelKey:@"Home",
                          kScentTypeKey: @(SENScentTypeHome) },
                        @{kScentLabelKey:@"Food",
                          kScentTypeKey: @(SENScentTypeFood) },
                        @{kScentLabelKey:@"Nature",
                          kScentTypeKey: @(SENScentTypeNature) },
                        @{kScentLabelKey:@"Space",
                          kScentTypeKey: @(SENScentTypeSpace) },
                        ];

        _ble = [[BLE alloc] init];
        [_ble controlSetup];
        _ble.delegate = self;
    }
    return self;
}

#pragma mark - BLEDelegate

-(void)bleDidDisconnect
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.isConnected = NO;
}

-(void)bleDidConnect
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    // send reset
    UInt8 buf[] = {0x04, 0x00, 0x00};
    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [self.ble write:data];
    
    self.isConnected = YES;
}

-(void)bleDidReceiveData:(unsigned char *)data length:(int)length;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    // byte 0 commandId
    // byte 1 scentId
    // byte 2 not used

    // parse data, all commands are in 3-byte
    for (int i = 0; i < length; i+=3) {
        // NSLog(@"0x%02X, 0x%02X, 0x%02X", data[i], data[i+1], data[i+2]);

        uint8_t commandId = data[i];

        if (commandId == 0x10) { // emit scent command
            // UInt16 payload = data[i+2] | data[i+1] << 8;
            uint8_t scentType = data[i+1];
            NSLog(@"emit scent command, type: %d", scentType);
        }
        else if (commandId == 0x1a) { // scent selected command
            uint8_t scentType = data[i+1];
            NSLog(@"scent selected command, type: %d", scentType);
        }
    }

}


/* Send command to Arduino to enable analog reading */
-(void)sendDigitalEnabled:(BOOL)state
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    uint8_t buf[3] = {0x01, 0x00, 0x00};

    if (state) {
        buf[1] = 0x01;
    }
    else {
        buf[1] = 0x00;
    }

    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [self.ble write:data];

    if (state) {
        @weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            [self sendDigitalEnabled:NO];
        });
    }
}


-(void)emitScentType:(SENScentType)type;
{
    NSLog(@"%s %d", __PRETTY_FUNCTION__, type);
    if (type == SENScentTypeNotSet) {
        return;
    }

    uint8_t buf[3] = {0x10, 0x00, 0x00};
    buf[1] = (uint8_t)(type & 0xff);

    NSData *data = [[NSData alloc] initWithBytes:buf length:3];
    [self.ble write:data];
}

-(void)scanForPeripheralWithCallback:(void (^)(BOOL success))block;
{
    // clear out the peripheral list.
    if (self.ble.peripherals) {
        self.ble.peripherals = nil;
    }

    // find some peripherals, for two seconds
    [self.ble findBLEPeripherals:2];

    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        if (block) {
            if ([self.ble.peripherals count] > 0) {
                block(YES);
                return;
            }
            block(NO);
        }
    });
}

-(void)disconnectFromPeripheral;
{
    // disconnect if already connected.
    if (self.ble.activePeripheral) {
        if(self.ble.activePeripheral.state == CBPeripheralStateConnected) {
            [[self.ble CM] cancelPeripheralConnection:[self.ble activePeripheral]];
        }
    }
}

-(void)connectToPeripheral;
{
    if (self.ble.peripherals.count > 0) {
        [self.ble connectPeripheral:[self.ble.peripherals objectAtIndex:0]];
    }
}

@end
