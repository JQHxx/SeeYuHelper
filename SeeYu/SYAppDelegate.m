//
//  AppDelegate.m
//  SeeYu
//
//  Created by trc on 2019/01/29.
//  Copyright © 2019年 fljj. All rights reserved.
//

#import "SYAppDelegate.h"
#import "SYHomePageVC.h"
#import "SYNewFeatureViewModel.h"
#import "SYBootRegisterVM.h"

#if defined(DEBUG)||defined(_DEBUG)
#import <JPFPSStatus/JPFPSStatus.h>
#import "SYDebugTouchView.h"
//#import <FBMemoryProfiler/FBMemoryProfiler.h>
//#import <FBRetainCycleDetector/FBRetainCycleDetector.h>
//#import "CacheCleanerPlugin.h"
//#import "RetainCycleLoggerPlugin.h"
#endif
@interface AppDelegate ()

/// APP管理的导航栏的堆栈
@property (nonatomic, readwrite, strong) SYNavigationControllerStack *navigationControllerStack;
/// APP的服务层
@property (nonatomic, readwrite, strong) SYViewModelServicesImpl *services;

@end

@implementation AppDelegate

//// 应用启动会调用的
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    /// 初始化UI之前配置
    [self _configureApplication:application initialParamsBeforeInitUI:launchOptions];
    
    // Config Service
    self.services = [[SYViewModelServicesImpl alloc] init];
    // Config Nav Stack
    self.navigationControllerStack = [[SYNavigationControllerStack alloc] initWithServices:self.services];
    // Configure Window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    // 重置rootViewController
    SYVM *vm = [self _createInitialViewModel];
    [self.services resetRootViewModel:vm];
    // 让窗口可见
    [self.window makeKeyAndVisible];
    
    /// 初始化UI后配置
    [self _configureApplication:application initialParamsAfterInitUI:launchOptions];
    
#if defined(DEBUG)||defined(_DEBUG)
    /// 调试模式
    [self _configDebugModelTools];
#endif
    
    // Save the application version info. must write last
    [[NSUserDefaults standardUserDefaults] setValue:SY_APP_VERSION forKey:SYApplicationVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSDictionary *remoteNotificationUserInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    NSLog(@"收到的推送消息内容为:%@",remoteNotificationUserInfo);
    return YES;
}



#pragma mark - 在初始化UI之前配置
- (void)_configureApplication:(UIApplication *)application initialParamsBeforeInitUI:(NSDictionary *)launchOptions
{
    /// 显示状态栏
    [application setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    /// 配置键盘
    [self _configureKeyboardManager];
    
    /// 配置文件夹
    [self _configureApplicationDirectory];
    
    /// 配置FMDB
    [self _configureFMDB];
    
    // 初始化环信服务
    EMOptions *options = [EMOptions optionsWithAppkey:@"1177170805178930#seeyu"];
    options.apnsCertName = @"seeyu_aps_dev";
    [[EMClient sharedClient] initializeSDKWithOptions:options];
    [[EMClient sharedClient] addDelegate:self delegateQueue:nil];
    
    // 注册推送, 用于iOS8以及iOS8之后的系统
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
    [application registerUserNotificationSettings:settings];
}

/// 配置文件夹
- (void)_configureApplicationDirectory
{
    /// 创建doc
    [SYFileManager createDirectoryAtPath:SYSeeYuDocDirPath()];
    /// 创建cache
    [SYFileManager createDirectoryAtPath:SYSeeYuCacheDirPath()];
    
    NSLog(@"SYSeeYuDocDirPath is [ %@ ] \n SYSeeYuCacheDirPath is [ %@ ]" , SYSeeYuDocDirPath() , SYSeeYuCacheDirPath());
}

/// 配置键盘管理器
- (void)_configureKeyboardManager {
    IQKeyboardManager.sharedManager.enable = YES;
    IQKeyboardManager.sharedManager.enableAutoToolbar = NO;
    IQKeyboardManager.sharedManager.shouldResignOnTouchOutside = YES;
}

/// 配置FMDB
- (void) _configureFMDB
{
//    [[FMDatabaseQueue sharedInstance] inDatabase:^(FMDatabase *db) {
//        NSString *version = [[NSUserDefaults standardUserDefaults] valueForKey:SBApplicationVersionKey];
//        if (![version isEqualToString:SB_APP_VERSION]) {
//            NSString *path = [[NSBundle mainBundle] pathForResource:@"senba_empty_1.0.0" ofType:@"sql"];
//            NSString *sql  = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//            /// 执行文件
//            if (![db executeStatements:sql]) {
//                SBLogLastError(db);
//            }
//        }
//    }];
}

#pragma mark - 在初始化UI之后配置
- (void)_configureApplication:(UIApplication *)application initialParamsAfterInitUI:(NSDictionary *)launchOptions
{
    /// 配置ActionSheet
    [LCActionSheet sy_configureActionSheet];
    
    /// 预先配置平台信息
//    [SBUMengService configureUMengPreDefinePlatforms];
    
    /// 设置状态栏全局字体颜色
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    @weakify(self);
    /// 监听切换根控制器的通知
    [[SYNotificationCenter rac_addObserverForName:SYSwitchRootViewControllerNotification object:nil] subscribeNext:^(NSNotification * note) {
        /// 这里切换根控制器
        @strongify(self);
        // 重置rootViewController
        SYSwitchRootViewControllerFromType fromType = [note.userInfo[SYSwitchRootViewControllerUserInfoKey] integerValue];
        NSLog(@"fromType is  %zd" , fromType);
        /// 切换根控制器
        SYVM *vm = [self _createInitialViewModel];
        if ([vm isKindOfClass:[SYHomePageVM class]]) {
            EMError *error = [[EMClient sharedClient] loginWithUsername:self.services.client.currentUser.userId password:self.services.client.currentUser.userPassword];
            if (!error) {
                [[EMClient sharedClient].options setIsAutoLogin:YES];
                [MBProgressHUD sy_showTips:@"登录成功"];
                [self.services resetRootViewModel:vm];
            } else {
                NSLog(@"%@",error);
                [MBProgressHUD sy_showError:error.errorDescription];
            }
        } else {
            [self.services resetRootViewModel:vm];
        }
        /// 切换了根控制器，切记需要将指示器 移到window的最前面
#if defined(DEBUG)||defined(_DEBUG)
        [self.window bringSubviewToFront:[SYDebugTouchView sharedInstance]];
#endif
    }];
    
    /// 配置H5
//    [SBConfigureManager configure];
}

#pragma mark - 调试(DEBUG)模式下的工具条
- (void)_configDebugModelTools
{
    
#if defined(DEBUG)||defined(_DEBUG)
    /// 显示FPS
    [[JPFPSStatus sharedInstance] open];
    
    /// 打开调试按钮
    [SYDebugTouchView sharedInstance];
    /// CoderMikeHe Fixed: 切换了根控制器，切记需要将指示器 移到window的最前面
    [self.window bringSubviewToFront:[SYDebugTouchView sharedInstance]];
#endif
}

#pragma mark - 创建根控制器
- (SYVM *)_createInitialViewModel {
    // The user has logged-in.
    NSString *version = [[NSUserDefaults standardUserDefaults] valueForKey:SYApplicationVersionKey];
    /// 版本不一样就先走 新特性界面
    if (![version isEqualToString:SY_APP_VERSION]) {
        return [[SYNewFeatureViewModel alloc] initWithServices:self.services params:nil];
    } else {
        /// 这里判断一下
        if ([SAMKeychain rawLogin] && self.services.client.currentUser) {
            /// 已经登录，跳转到主页
            return [[SYHomePageVM alloc] initWithServices:self.services params:nil];
        } else {
            /// 进入注册页面
            return [[SYBootRegisterVM alloc] initWithServices:self.services params:nil];
        }
    }
}

#pragma mark 环信delegate
- (void)autoLoginDidCompleteWithError:(EMError *)aError {
    NSLog(@"登录异常为：%@",aError);
}

#pragma mark- 获取appDelegate
+ (AppDelegate *)sharedDelegate{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

// 注册用户通知设置
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings: (UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

// 上传deviceToekn到环信服务器
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"deviceToken:%@",token);
    [[EMClient sharedClient] bindDeviceToken:deviceToken];
}

// 注册deviceToken失败
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"error -- %@",error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    // userInfo为远程推送的内容
    NSLog(@"收到的远程推送内容为:%@",userInfo);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[EMClient sharedClient] applicationDidEnterBackground:application];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[EMClient sharedClient] applicationWillEnterForeground:application];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
