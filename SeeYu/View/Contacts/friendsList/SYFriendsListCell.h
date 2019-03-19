//
//  SYFriendsListCell.h
//  SeeYu
//
//  Created by 唐荣才 on 2019/3/15.
//  Copyright © 2019 fljj. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SYFriendsListCell : UITableViewCell

@property (nonatomic, strong) NSString *friendId;

@property (nonatomic, strong) UIImageView *headImageView;

@property (nonatomic, strong) UILabel *aliasLabel;

@property (nonatomic, strong) UIView *badgeView;

@end

NS_ASSUME_NONNULL_END
