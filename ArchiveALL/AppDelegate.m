//
//  AppDelegate.m
//  ArchiveALL
//
//  Created by songfei on 14-2-12.
//  Copyright (c) 2014年 songfei. All rights reserved.
//

#import "AppDelegate.h"

#import "SFArchiveFileItem.h"

#import "SF7zArchive.h"
#import "SFRarArchive.h"
#import "SFZipArchive.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    NSString *outPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)[0];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"中文" ofType:@"7z"];
    
    SF7zArchive* arc = [[SF7zArchive alloc] initWithFilePath:path];
    
    NSArray* array = [arc listFileItem];
    
    for(SFArchiveFileItem* item in array)
    {
        NSLog(@"%@ %@",item.createDate, item.fullPathName);
    }
    
    
    NSLog(@"------------------------------------");
    
    NSString* rarPath = [[NSBundle mainBundle] pathForResource:@"中文" ofType:@"rar"];
    
    SFRarArchive* rarArc = [[SFRarArchive alloc] initWithFilePath:rarPath];
    
    NSArray* rarArray = [rarArc listFileItem];
    
    for(SFArchiveFileItem* item in rarArray)
    {
        NSLog(@"%@ %@",item.createDate, item.fullPathName);
    }
    
    NSLog(@"------------------------------------");
    
    NSString* zipPath = [[NSBundle mainBundle] pathForResource:@"中文" ofType:@"zip"];
    
    SFZipArchive* zipArc = [[SFZipArchive alloc] initWithFilePath:zipPath];
    
    NSArray* zipArray = [zipArc listFileItem];
    
    for(SFArchiveFileItem* item in zipArray)
    {
        NSLog(@"%@ %@",item.createDate, item.fullPathName);
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
