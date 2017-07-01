//
//  AppDelegate.h
//  BaiDuPoiSearch
//
//  Created by Wynter on 2017/5/15.
//  Copyright © 2017年 Wynter. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <BaiduMapAPI_Base/BMKBaseComponent.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate,BMKGeneralDelegate>
@property (nonatomic,strong) BMKMapManager* mapManager;
@property (strong, nonatomic) UIWindow *window;


@end

