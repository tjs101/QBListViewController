//
//  QBListTableViewCell.m
//  QBFramework
//
//  Created by quentin on 2016/11/11.
//  Copyright © 2016年 quentin. All rights reserved.
//

#import "QBListTableViewCell.h"

@implementation QBListTableViewCell

- (void)setModel:(QBModel *)model
{
    _model = model;
    
    [self setNeedsLayout];
}

- (void)didSelectRow
{
    
}

+ (CGFloat)heightWithModel:(QBModel *)model
{
    return 0;
}

@end
