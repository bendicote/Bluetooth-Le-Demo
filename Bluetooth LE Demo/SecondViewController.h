//
//  SecondViewController.h
//  Bluetooth LE Demo
//
//  Created by CHIA HAO HSU on 2014/11/18.
//  Copyright (c) 2014年 Esignal. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "BLE.h"

@interface SecondViewController : UIViewController

@property (strong, nonatomic) BLE *bleShieldSeque;

@property (weak, nonatomic) IBOutlet UITextView *DataText;

@property (weak, nonatomic) IBOutlet UITextField *SendText;
@end


@interface SecondViewController ()<BLEDelegate,UITextFieldDelegate>
{
    BLE *bleShield;
}
@end