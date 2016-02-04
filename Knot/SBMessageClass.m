//
//  SBMessageClass.m
//  Knot
//
//  Created by Nathan Mueller on 2/1/16.
//  Copyright © 2016 Knot App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBMessageClass.h"
#import "SendBird/MessagingTableViewController.h"


@implementation SBMessageClass


- (void)startSendBirdMessaging
{
    NSString *APP_ID = @"6D1F1F00-D8E0-4574-A738-4BDB61AF0411";
    NSString *USER_ID = [SendBirdUtils deviceUniqueID];
    NSString *USER_NAME = [NSString stringWithFormat:@"User-%@", [USER_ID substringToIndex:5]];
    NSString *CHANNEL_URL = @"jia_test.Lobby";
    
    MessagingTableViewController *viewController = [[MessagingTableViewController alloc] init];
    
    [SendBird initAppId:APP_ID withDeviceId:[SendBird deviceUniqueID]];
    
    [viewController setViewMode:kMessagingChannelListViewMode];
    [viewController initChannelTitle];
    [viewController setChannelUrl:CHANNEL_URL];
    [viewController setUserName:USER_NAME];
    [viewController setUserId:USER_ID];
    /*
    [self.navigationController setModalPresentationStyle:UIModalPresentationCurrentContext];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navController setModalPresentationStyle:UIModalPresentationCurrentContext];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
     */
}

- (void)startSendBirdMessagingTarget
{
    NSString *APP_ID = @"6D1F1F00-D8E0-4574-A738-4BDB61AF0411";
    NSString *USER_ID = [SendBirdUtils deviceUniqueID];
    NSString *USER_NAME = [NSString stringWithFormat:@"User-%@", [USER_ID substringToIndex:5]];
    NSString *CHANNEL_URL = @"jia_test.Lobby";
    NSString *TARGET_USER_ID = @"XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX";
    
    MessagingTableViewController *viewController = [[MessagingTableViewController alloc] init];
    
    [SendBird initAppId:APP_ID withDeviceId:[SendBird deviceUniqueID]];
    
    [viewController setTargetUserId:TARGET_USER_ID];
    [viewController setViewMode:kMessagingViewMode];
    [viewController initChannelTitle];
    [viewController setChannelUrl:CHANNEL_URL];
    [viewController setUserName:USER_NAME];
    /*
    [self.navigationController setModalPresentationStyle:UIModalPresentationCurrentContext];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navController setModalPresentationStyle:UIModalPresentationCurrentContext];
    [self.navigationController presentViewController:navController animated:YES completion:nil];
     */
}
@end