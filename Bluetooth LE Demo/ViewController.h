//
//  ViewController.h
//
//  Bluetooth LE Demo Code
//
//  Created by CHIA HAO HSU on 2014/11/18.
//
//  Copyright (c) 2014年 Esignal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecondViewController.h"
#import "BLE.h"

@interface ViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>
{
    
}

@end

@interface ViewController ()<BLEDelegate,UITextFieldDelegate>
{
    
    BLE *bleShield;
    
}
@end

