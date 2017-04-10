//
//  QBListTableViewCell.h
//  QBFramework
//  配合QBListViewController使用
//  Created by quentin on 2016/11/11.
//  Copyright © 2016年 quentin. All rights reserved.
//

#import "QBTableViewCell.h"

@interface QBListTableViewCell : QBTableViewCell

@property (nonatomic, strong) QBModel *model;/**<QBModel*/
@property (nonatomic, strong) id typeValue;/**<改变cell样式>*/

- (void)didSelectRow;// 选中行

+ (CGFloat)heightWithModel:(QBModel *)model;// 高度

@end
