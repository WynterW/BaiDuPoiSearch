//
//  ViewController.m
//  BaiDuPoiSearch
//
//  Created by Wynter on 2017/5/15.
//  Copyright © 2017年 Wynter. All rights reserved.
//

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define PAGECAPACITY 20  // 分页量

#import "ViewController.h"
#import "SearchPoiResultListTableViewController.h"
#import <MJRefresh/MJRefresh.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>//引入base相关所有的头文件
#import <BaiduMapAPI_Map/BMKMapComponent.h>//引入地图功能所有的头文件
#import <BaiduMapAPI_Search/BMKSearchComponent.h>//引入检索功能所有的头文件
#import <BaiduMapAPI_Location/BMKLocationComponent.h>//引入定位功能所有的头文件

@interface ViewController ()<BMKMapViewDelegate,BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,BMKPoiSearchDelegate,UITableViewDelegate,UITableViewDataSource,UISearchControllerDelegate,UISearchResultsUpdating,UISearchBarDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, assign) BOOL setCenter;
@property (nonatomic, strong) BMKMapView *mapView;
@property (nonatomic, strong) BMKLocationService *locService;
@property (nonatomic, strong) BMKGeoCodeSearch *geocodesearch;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSMutableArray <BMKPoiInfo*>*poiResultAry;
@property (nonatomic, assign) int pageIndex;/**< 当前页码*/
@property (nonatomic, strong) NSString *searchText;/**< 搜索文本*/

@end

@implementation ViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMapView];
    self.navigationItem.titleView = self.searchController.searchBar;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.mapView viewWillAppear];
    self.mapView.delegate = self;
    _locService.delegate = self;
    _geocodesearch.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:YES];
    [self.mapView viewWillDisappear];
    self.mapView.delegate = nil;
    _locService.delegate = nil;
    _geocodesearch.delegate = nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.poiResultAry.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textColor = UIColorFromRGB(0x555555);
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.textColor = UIColorFromRGB(0x888888);
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
    }
    BMKPoiInfo *info = self.poiResultAry[indexPath.row];
    cell.textLabel.text = info.name;
    cell.detailTextLabel.text = info.address;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //POI详情检索
    BMKPoiInfo *info = self.poiResultAry[indexPath.row];
    BMKPoiSearch *poisearch = [[BMKPoiSearch alloc] init];
    poisearch.delegate = self;
    BMKPoiDetailSearchOption* option = [[BMKPoiDetailSearchOption alloc] init];
    option.poiUid = info.uid;
    [poisearch poiDetailSearch:option];
}

#pragma mark - mapview delegate
// 用户方向更新后，会调用此函数
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation {
    [_mapView updateLocationData:userLocation];
    _coordinate = userLocation.location.coordinate;
}

// 用户位置更新后，会调用此函数
-(void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
    [_mapView updateLocationData:userLocation];
    _coordinate = userLocation.location.coordinate;
    
    if (_setCenter == YES) {
        [self centerCoordinate];
    }
    _setCenter = NO;
}

#pragma mark -根据anntation生成对应的View
- (BMKAnnotationView *)mapView:(BMKMapView *)view viewForAnnotation:(id <BMKAnnotation>)annotation {
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        newAnnotationView.pinColor = BMKPinAnnotationColorRed;
        newAnnotationView.animatesDrop = YES;
        return newAnnotationView;
    }
    return nil;
}

#pragma mark - BMKPoiSearchDelegate
#pragma mark 搜索结果列表
- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResultList errorCode:(BMKSearchErrorCode)error {
    SearchPoiResultListTableViewController *result = (SearchPoiResultListTableViewController *)self.searchController.searchResultsController;
    self.pageIndex = poiResultList.pageIndex;
    if (poiResultList.pageIndex == poiResultList.pageNum || poiResultList.currPoiNum < PAGECAPACITY) {
        [result.tableView.mj_footer endRefreshingWithNoMoreData];
    } else {
        [result.tableView.mj_footer resetNoMoreData];
    }
    
    if (poiResultList.pageIndex == 0) {
        self.poiResultAry = [NSMutableArray new];
    }
    
    for (BMKPoiInfo *info in poiResultList.poiInfoList) {
        [self.poiResultAry addObject:info];
    }
    
    [result.tableView reloadData];
}

#pragma mark 搜索结果详情
-(void)onGetPoiDetailResult:(BMKPoiSearch *)searcher result:(BMKPoiDetailResult *)poiDetailResult errorCode:(BMKSearchErrorCode)errorCode {
    if(errorCode == BMK_SEARCH_NO_ERROR){
        NSString *resultStr = [NSString stringWithFormat:@"名称：%@\n地址：%@\n标签：%@\n电话：%@\n图片地址：%@", poiDetailResult.name, poiDetailResult.address, poiDetailResult.tag, poiDetailResult.phone, poiDetailResult.detailUrl];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"搜索结果详情" message:resultStr preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [_searchController dismissViewControllerAnimated:YES completion:nil];
            
        }];
        [alert addAction:sureAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        [_mapView removeAnnotations:_mapView.annotations];
        
        BMKPointAnnotation* annotation = [[BMKPointAnnotation alloc]init];
        annotation.coordinate = poiDetailResult.pt;
        annotation.title = resultStr;
        [_mapView addAnnotation:annotation];
        
        [_mapView setCenterCoordinate:poiDetailResult.pt animated:YES];
    }
}

#pragma mark - UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.searchText = searchController.searchBar.text;
    [self listRequestWithSearchText:searchController.searchBar.text refresh:YES];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (searchBar.text.length == 0) {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.mapView removeAnnotations:self.mapView.annotations];
}

#pragma mark - UIScrollViewDelegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([_searchController.searchBar isFirstResponder] && self.poiResultAry.count > 0) {
        [_searchController.searchBar resignFirstResponder];
    }
}

#pragma mark - requestData
- (void)listRequestWithSearchText:(NSString *)searchText refresh:(BOOL)isRefresh {
    BMKPoiSearch *searcher =[[BMKPoiSearch alloc]init];
    searcher.delegate = self;
    //发起检索
    BMKNearbySearchOption *option = [[BMKNearbySearchOption alloc]init];
    if (isRefresh) {
        option.pageIndex = 0;
    } else {
        option.pageIndex = ++self.pageIndex;
    }
    option.pageCapacity = PAGECAPACITY; //分页量
    option.location = self.coordinate;
    option.keyword = searchText;
    option.radius = 3000;
    
    [searcher poiSearchNearBy:option];
}

#pragma mark - private methods
#pragma mark -开始定位
- (void)showCurrentLocation {
    [_locService startUserLocationService];
    _mapView.showsUserLocation = NO;//先关闭显示的定位图层
    _mapView.userTrackingMode = BMKUserTrackingModeHeading;
    _mapView.showsUserLocation = YES;//显示定位图层
}

- (void)centerCoordinate {
    [_mapView setCenterCoordinate:_coordinate animated:YES];
}

// 添加搜索到的所有坐标
- (void) addPointAnnotation {
    for (BMKPoiInfo *info in self.poiResultAry) {
        BMKPointAnnotation* annotation = [[BMKPointAnnotation alloc]init];
        annotation.coordinate = info.pt;
        annotation.title = info.address;
        [_mapView addAnnotation:annotation];
    }
}

#pragma mark - getters and  setters
#pragma mark - 初始化地图
- (void)initMapView {
    self.mapView = [[BMKMapView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    
    _locService = [[BMKLocationService alloc]init];
    _geocodesearch = [[BMKGeoCodeSearch alloc]init];
    _locService.delegate = self;
    _geocodesearch.delegate = self;
    self.mapView.delegate = self;
    // 设定定位的最小更新距离，这里设置 200m 定位一次，频繁定位会增加耗电量
    _locService.distanceFilter = 200;
    // 设定定位精度
    _locService.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    // 设定是否显式比例尺
    _mapView.showMapScaleBar = YES;
    // 设定比例尺位置
    _mapView.mapScaleBarPosition = CGPointMake(_mapView.frame.size.width - 70, CGRectGetHeight(_mapView.bounds) - 30);
    // 设置放大级别
    _mapView.zoomLevel = 15;
    _setCenter = YES;
    
    // 定位
    [self showCurrentLocation];
}

- (NSMutableArray<BMKPoiInfo *> *)poiResultAry {
    if (!_poiResultAry) {
        _poiResultAry = [NSMutableArray new];
    }
    return _poiResultAry;
}

- (UISearchController *)searchController {
    if (!_searchController) {
        SearchPoiResultListTableViewController *result = [[SearchPoiResultListTableViewController alloc] init];
        result.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        result.tableView.delegate = self;
        result.tableView.dataSource = self;
        result.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        result.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
            [self listRequestWithSearchText:self.searchText refresh:NO];
        }];
        _searchController = [[UISearchController alloc] initWithSearchResultsController:result];
        _searchController.searchBar.tintColor = UIColorFromRGB(0x353535);
        _searchController.searchResultsUpdater = self;
        _searchController.searchBar.delegate = self;
        _searchController.searchBar.placeholder = @"输入地点";
        _searchController.searchBar.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44.0);

        self.definesPresentationContext = YES;
        // 设置NO向下偏移64个像素
        self.searchController.hidesNavigationBarDuringPresentation = NO;
    }
    return _searchController;
}

@end
