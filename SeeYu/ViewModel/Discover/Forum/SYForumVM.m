//
//  SYForumVM.m
//  SeeYu
//
//  Created by 唐荣才 on 2019/3/25.
//  Copyright © 2019 fljj. All rights reserved.
//

#import "SYForumVM.h"
#import "SYForumModel.h"
#import "SYForumCommentVM.h"

@implementation SYForumVM

- (void)initialize {
    self.pageSize = 10; // 每次加载10条数据
    @weakify(self)
    self.requestForumsCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSString *page) {
        @strongify(self)
        NSArray * (^mapAllForums)(NSArray *) = ^(NSArray *forums) {
            return forums.rac_sequence.array;
        };
        NSDictionary *params = @{@"userId":self.services.client.currentUser.userId,@"pageNum":page,@"pageSize":@(self.pageSize)};
        SYKeyedSubscript *subscript = [[SYKeyedSubscript alloc]initWithDictionary:params];
        SYURLParameters *paramters = [SYURLParameters urlParametersWithMethod:SY_HTTTP_METHOD_POST path:SY_HTTTP_PATH_USER_FORUM_LIST parameters:subscript.dictionary];
        return [[[[self.services.client enqueueRequest:[SYHTTPRequest requestWithParameters:paramters] resultClass:[SYForumModel class]] sy_parsedResults] map:mapAllForums] takeUntil:self.rac_willDeallocSignal];
    }];
    [self.requestForumsCommand.executionSignals.switchToLatest.deliverOnMainThread subscribeNext:^(NSArray *array) {
        self.datasource = array;
    }];
    [self.requestForumsCommand.errors subscribeNext:^(NSError *error) {
        [MBProgressHUD sy_showErrorTips:error];
    }];
    self.enterForumsDetailViewCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(NSDictionary *params) {
        SYForumCommentVM *vm = [[SYForumCommentVM alloc] initWithServices:self.services params:params];
        [self.services pushViewModel:vm animated:YES];
        return [RACSignal empty];
    }];
}

@end
