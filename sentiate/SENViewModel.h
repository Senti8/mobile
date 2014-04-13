//
//  SENViewModel.h
//  sentiate
//
//  Created by Robert Carlsen on 4/12/14.
//  Copyright (c) 2014 Robert Carlsen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLE.h"

typedef NS_ENUM(NSInteger, SENScentType){
    SENScentTypeNotSet = 0,
    SENScentTypeSoil,
    SENScentTypeHome,
    SENScentTypeFood,
    SENScentTypeNature,
    SENScentTypeSpace,
    SENScentTypeFire
};

extern NSString *const kScentTypeKey;
extern NSString *const kScentLabelKey;
extern NSString *const kScentImageKey;

@interface SENViewModel : NSObject
@property(nonatomic, strong)NSArray *scentItems;
@property(nonatomic, strong)BLE *ble;

@property(nonatomic)BOOL isConnected;

-(void)sendDigitalEnabled:(BOOL)state;
-(void)emitScentType:(SENScentType)type;

-(void)scanForPeripheralWithCallback:(void (^)(BOOL success))block;
-(void)connectToPeripheral;
-(void)disconnectFromPeripheral;

@end
