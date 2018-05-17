//
//  AppDelegate.m
//  YJDownloadManagerDemo
//
//  Created by cool on 2018/5/17.
//  Copyright © 2018 cool. All rights reserved.
//

#import "AppDelegate.h"
#import "HJDownloadTabBar_VC.h"
#import "YJDownloadManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    /// 下载状态改变的通知
    [YJDownloadNoteCenter addObserver:self selector:@selector(downloadNotification:) name:YJDownloadStateDidChangeNotification object:nil];
    [YJDownloadNoteCenter addObserver:self selector:@selector(downloadProgressNotification:) name:YJDownloadProgressDidChangeNotification object:nil];
    HJDownloadTabBar_VC *tabBarVC = [[HJDownloadTabBar_VC alloc] init];
    self.window.rootViewController = tabBarVC;
    
    [[YJDownloadManager sharedManager] setMaxConcurrentOperationCount:3];
    [[YJDownloadManager sharedManager] enableProgressLog:NO];
    
    return YES;
}

- (void)downloadNotification:(NSNotification *)no {
    YJDownloadModel * downloadModel = no.userInfo[YJDownloadInfoKey];
    
    NSLog(@"下载状态%@",downloadModel.statusText);
}

- (void)downloadProgressNotification:(NSNotification *)no {
    YJDownloadModel * downloadModel = no.userInfo[YJDownloadInfoKey];
    
    NSLog(@"下载进度%@",downloadModel.statusText);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
