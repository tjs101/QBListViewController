//
//  QBListViewController.h
//  QBFramework
//  纯列表基类
//  classNameOfCell需要继承QBListTableViewCell
//  classNameOfModel需要继承SQBModel
//  内含分页逻辑，传递参数是不需要传递分页参数
//  Created by quentin on 2016/11/10.
//  Copyright © 2016年 quentin. All rights reserved.
//

#import "QBTableViewController.h"

@interface QBListViewController : QBTableViewController

- (instancetype)initWithURL:(NSString *)url parameters:(NSDictionary *)parameters classNameOfCell:(NSString *)classNameOfCell classNameOfModel:(NSString *)classNameOfModel;

@property (nonatomic, assign) BOOL autoCacheData;/**<是否自动进行缓存，默认为NO，不使用自动缓存*/
@property (nonatomic, copy) NSString *nullDataDesc;/**<没有数据的描述，默认为“没有任何数据”*/
@property (nonatomic, assign) CGFloat nullCellHeight;/**<无数据页面显示高度，默认为整个页面高度>*/

@property (nonatomic, assign) BOOL showCellState;/**<设置cell背景，默认为YES*/

@property (nonatomic, strong) id typeValue;/**<传入一个修改cell样式的随意值>*/
@property (nonatomic, strong) id<NSCopying> compareKey;/**<增量查询参数key>*/
@property (nonatomic, strong) id compareValue;/**<增量查询参数value>*/

- (void)changeParmeters:(NSDictionary *)parmeters;// 同一个接口、Cell、Model切换传入参数差异
- (void)changeParmeters:(NSDictionary *)parmeters url:(NSString *)url;// 同一Cell、Model切换传入参数差异
- (void)changeParmeters:(NSDictionary *)parmeters url:(NSString *)url classNameOfCell:(NSString *)classNameOfCell;// 同一Model切换传入参数差异
- (void)changeParmeters:(NSDictionary *)parmeters url:(NSString *)url classNameOfCell:(NSString *)classNameOfCell classNameOfModel:(NSString *)classNameOfModel;// 切换传入参数差异

@end
