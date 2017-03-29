//
//  QBListViewController.m
//  QBFramework
//
//  Created by quentin on 2016/11/10.
//  Copyright © 2016年 quentin. All rights reserved.
//

#import "QBListViewController.h"
#import "QBListTableViewCell.h"
#import "QBModel.h"
#import "MBProgressHUD.h"

@interface QBListViewController ()

{
    NSInteger   _currentPage;
    BOOL        _reloading;// 是否加载更多
    BOOL        _nullNetData;
    
    
    NSURL           *_url;
    NSDictionary    *_parameters;
    NSString        *_classNameOfCell;
    NSString        *_classNameOfModel;
    
    MBProgressHUD   *_progressHud;
}

@property (nonatomic, strong) QBServerRequest *listServerRequest;
@property (nonatomic, strong) NSMutableArray  *items;

@end

@implementation QBListViewController
@synthesize listServerRequest;

- (void)setListServerRequest:(QBServerRequest *)aListServerRequest
{
    
    [listServerRequest cancelAndClearDelegate];
    listServerRequest = aListServerRequest;
    
}

- (instancetype)initWithURL:(NSString *)url parameters:(NSDictionary *)parameters classNameOfCell:(NSString *)classNameOfCell classNameOfModel:(NSString *)classNameOfModel
{
    if (self = [super init]) {
        
        _url = [NSURL URLWithString:url];
        
        _parameters = [NSDictionary dictionaryWithDictionary:parameters];
        _classNameOfCell = classNameOfCell;
        _classNameOfModel = classNameOfModel;
        
        _showCellState = YES;
        
    }
    return self;
}

- (void)viewDidLoad {
    
    self.hasPullRefresh = YES;
    self.hasLoadMoreView = YES;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.viewName = self.navigationTitle;
    
    ADD_BACK(back);
    
    _nullCellHeight = CGRectGetHeight(self.view.frame);
    _nullDataDesc = @"没有任何数据";
    
    self.items = [NSMutableArray array];
    
    [self triggerPullToRefresh];
}

- (void)back
{
    [_progressHud hide:YES];
    self.listServerRequest = nil;
    
    [super back];
}

#pragma mark - changeParmeters

- (void)changeParmeters:(NSDictionary *)parmeters
{
    [self changeParmeters:parmeters url:_url.absoluteString];
}

- (void)changeParmeters:(NSDictionary *)parmeters url:(NSString *)url
{
    [self changeParmeters:parmeters url:url classNameOfCell:_classNameOfCell];
}

- (void)changeParmeters:(NSDictionary *)parmeters url:(NSString *)url classNameOfCell:(NSString *)classNameOfCell
{
    [self changeParmeters:parmeters url:url classNameOfCell:classNameOfCell classNameOfModel:_classNameOfModel];
}

- (void)changeParmeters:(NSDictionary *)parmeters url:(NSString *)url classNameOfCell:(NSString *)classNameOfCell classNameOfModel:(NSString *)classNameOfModel
{
    [self.tableView setContentOffset:CGPointZero];
    
    _parameters = [NSDictionary dictionaryWithDictionary:parmeters];
    _classNameOfCell = classNameOfCell;
    _classNameOfModel = classNameOfModel;
    _url = [NSURL URLWithString:url];
    
    _nullNetData = NO;// 切换时判断是否有网络
    
    [self triggerPullToRefresh];
}

#pragma mark - request data

- (void)requestReportListDataWithPage:(NSInteger)page
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(page) forKey:@"currentPage"];
    [dict setObject:@(kPageSize) forKey:@"showNum"];
    
    // 增量ID
    if (_compareKey && _compareValue) {
        [dict setObject:_compareValue forKey:_compareKey];
    }
    
    for (NSString *key in [_parameters allKeys]) {
        
        id obj = [_parameters objectForKey:key];
        if (obj) {
            [dict setObject:obj forKey:key];
        }
        
    }
    
    [_progressHud hide:YES];
    _progressHud = nil;
    
    if (page == kFirstPage) {
        _progressHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    
    QBServerRequest *request = [QBServerRequest requestWithURL:_url];
    request.delegate = self;
    request.parameters = dict;
    request.showErrorHint = YES;
    request.autoCacheData = (page == kFirstPage) && _autoCacheData;
    self.listServerRequest = request;
    [request setHTTPCacheComplete:^(NSDictionary *cacheData) {
        
        
        id value = [cacheData objectForKey:@"data"];
        
        if ([value isKindOfClass:[NSArray class]]) {
            
            for (NSDictionary *dict in value) {
                id obj = [[NSClassFromString(_classNameOfModel) alloc] init];
                if (obj) {
                    
                    if ([obj respondsToSelector:@selector(updateDataFromDictionary:)]) {
                        [obj updateDataFromDictionary:dict];
                        [self.items addObject:obj];
                    }
                    
                }
            }
            
        }
        
        [self reloadView];
    }];
    [request setHTTPComplete:^(QBServerRequest *serverRequest, NSDictionary *responseDict) {
        
        [_progressHud hide:YES];
        
        _currentPage = page;
        
        id value = [responseDict objectForKey:@"data"];
        
        if ([value isKindOfClass:[NSArray class]]) {
            
            if (page == kFirstPage) {
                [self.items removeAllObjects];
            }
            
            for (NSDictionary *dict in value) {
                
                id obj = [[NSClassFromString(_classNameOfModel) alloc] init];
                if (obj) {
                    
                    if ([obj respondsToSelector:@selector(updateDataFromDictionary:)]) {
                        [obj updateDataFromDictionary:dict];
                        [self.items addObject:obj];
                    }
                    
                }
            }
            
            // 返回数据大于请求数量时，动态列表用
            _reloading = ([value count] >= kPageSize);
        }
        
        _nullNetData = YES;
        
        [self reloadView];
    }];
    [request setHTTPFailed:^(QBServerRequest *serverRequest) {
        
        [_progressHud hide:YES];
        
        [self reloadView];
    }];
    
    [request startAsynchronousRequest];
}

#pragma mark - load/pull

- (void)triggerLoadMore
{
    [self requestReportListDataWithPage:_currentPage + 1];
}

- (void)triggerPullToRefresh
{
    [self requestReportListDataWithPage:kFirstPage];
}

- (BOOL)isLoadMoreViewNeeded
{
    return _reloading;
}

- (BOOL)nullData
{
    return _nullNetData && [self.items count] == 0;
}

#pragma mark - UITableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLoadMoreViewNeeded] && indexPath.row >= [self.items count]) {
        return self.loadMoreCell;
    }
    
    if ([self nullData]) {
        static NSString *reuseIdentifier = @"no data cell";
        
        static NSInteger titleTag = 100;
        if (cell == nil) {
            cell = [[SRTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
            
            cell.backgroundColor = kBackgroundColor;
            
            UILabel *titleLabel = [[UILabel alloc] init];
            titleLabel.textColor = colorFromRGB(0x767676);
            titleLabel.font = [UIFont systemFontOfSize:13];
            titleLabel.text = _nullDataDesc;
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [titleLabel sizeToFit];
            titleLabel.tag = titleTag;
            titleLabel.frame = CGRectMake((CGRectGetWidth(self.view.frame) - CGRectGetWidth(titleLabel.frame)) / 2, (_nullCellHeight - CGRectGetHeight(titleLabel.frame)) / 2 - 50, CGRectGetWidth(titleLabel.frame), CGRectGetHeight(titleLabel.frame));
            [cell addSubview:titleLabel];
            
        }
        
        id value = [cell viewWithTag:titleTag];
        if ([value isKindOfClass:[UILabel class]]) {
            
            UILabel *titleLabel = (UILabel *)value;
            titleLabel.text = _nullDataDesc;
            
            CGRect rect = titleLabel.frame;
            rect.origin.y = (_nullCellHeight - CGRectGetHeight(titleLabel.frame)) / 2 - 50;
            titleLabel.frame = rect;
        }
        
        return cell;
    }
    
    static NSString *reuseIdentifier = @"cell";
    id cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[NSClassFromString(_classNameOfCell) alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    
    if (indexPath.row >= [self.items count]) {
        return cell;
    }
    id item = [self.items objectAtIndex:indexPath.row];
    
    if ([cell respondsToSelector:@selector(setModel:)]) {
        [cell setModel:item];
    }
    

    if ([cell respondsToSelector:@selector(setTypeValue:)]) {
        [cell setTypeValue:_typeValue];
    }
    
    if (_showCellState) {
        if ([self.items count] == 1) {
            [cell changeBackgroundImageState:QBCellBackgroundImageStateSingle];
        }
        else {
            if (indexPath.row == 0) {
                [cell changeBackgroundImageState:QBCellBackgroundImageStateTop];
            }
            else {
                [cell changeBackgroundImageState:QBCellBackgroundImageStateOther];
            }
        }
    }
    
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self nullData]) {
        return 1;
    }
    if ([self isLoadMoreViewNeeded]) {
        return [self.items count] + 1;
    }
    
    return [self.items count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self nullData]) {
        return _nullCellHeight;
    }
    
    if ([self isLoadMoreViewNeeded] && indexPath.row >= [self.items count]) {
        return [QBLoadMoreCell height];
    }
    
    if (indexPath.row >= [self.items count]) {
        return 0;
    }
    
    id obj = [self.items objectAtIndex:indexPath.row];
    
    id cell = NSClassFromString(_classNameOfCell);
    if ([cell respondsToSelector:@selector(heightWithModel:)]) {
        
        double height = [cell heightWithModel:obj];
        return height;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self nullData]) {
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[QBListTableViewCell class]]) {
        
        QBListTableViewCell *aCell = (QBListTableViewCell *)cell;
        [aCell didSelectRow];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
