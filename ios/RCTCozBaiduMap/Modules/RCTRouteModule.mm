#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Utils/BMKGeometry.h>


@interface RCTRouteModule : NSObject <RCTBridgeModule, BMKRouteSearchDelegate>
@end

@implementation RCTRouteModule {
    BMKRouteSearch *_routeSearch;
    RCTPromiseResolveBlock _resolve;
    RCTPromiseRejectBlock _reject;
}

RCT_EXPORT_MODULE(BaiduMapRoute)


RCT_EXPORT_METHOD(routePlanByCoordinate:
                  (NSDictionary *)startPoint
                  end:(NSDictionary *)endPoint
                  routeType:(NSInteger)type
                  searchWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){

    BMKPlanNode* start = [[BMKPlanNode alloc]init];
    CLLocationCoordinate2D coor = [self getCoorFromMarkerOption:startPoint];
    start.pt = coor;
    BMKPlanNode* end = [[BMKPlanNode alloc]init];
    CLLocationCoordinate2D endCoor = [self getCoorFromMarkerOption:endPoint];
    end.pt = endCoor;

    _resolve = resolve;
    _reject = reject;
    if (!_routeSearch) {
        _routeSearch = [[BMKRouteSearch alloc]init];
        _routeSearch.delegate = self;
    }
    [self routOption:start end:end routeType:type];
}


- (void)routOption:(BMKPlanNode *)start end:(BMKPlanNode *)end routeType:(NSInteger)type {
    BOOL flag ;
    BMKDrivingRoutePlanOption *drivingRouteSearchOption = [[BMKDrivingRoutePlanOption alloc]init];
    drivingRouteSearchOption.from = start;
    drivingRouteSearchOption.to = end;
    drivingRouteSearchOption.drivingRequestTrafficType = BMK_DRIVING_REQUEST_TRAFFICE_TYPE_NONE;//不获取路况信息
    flag = [_routeSearch drivingSearch:drivingRouteSearchOption];
    if(type == 1) {
        BMKMassTransitRoutePlanOption *massTransitRouteOption = [[BMKMassTransitRoutePlanOption alloc]init];
        massTransitRouteOption.from = start;
        massTransitRouteOption.to = end;
        flag = [_routeSearch massTransitSearch:massTransitRouteOption];
    }
    if (type == 2) {
        BMKRidingRoutePlanOption *option = [[BMKRidingRoutePlanOption alloc]init];
        option.from = start;
        option.to = end;
        flag = [_routeSearch ridingSearch:option];

    }
    if(type == 3) {
        BMKWalkingRoutePlanOption *walkingRouteOption = [[BMKWalkingRoutePlanOption alloc] init];
        walkingRouteOption.from = start;
        walkingRouteOption.to = end;
        flag = [_routeSearch walkingSearch:walkingRouteOption];
    }

    if(flag)
    {
        NSLog(@"%ld检索发送成功",type);
    }
    else
    {
        NSLog(@"%ld检索发送失败",type);
    }
}

#pragma  mark  ---- Walking ---
- (void)onGetWalkingRouteResult:(BMKRouteSearch *)searcher result:(BMKWalkingRouteResult *)result errorCode:(BMKSearchErrorCode)error {
    NSLog(@"onGetWalkingRouteResult error:%d", (int)error);
    NSMutableDictionary *body = @{}.mutableCopy;

    if (error == BMK_SEARCH_NO_ERROR) {
        //成功获取结果
        BMKWalkingRouteLine* plan = (BMKWalkingRouteLine*)[result.routes objectAtIndex:0];

        // 计算路线方案中的路段数目
        NSInteger size = [plan.steps count];
        NSLog(@"%ld",size);
        int planPointCounts = 0;
        // NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i < size; i++) {
            BMKWalkingStep* transitStep = [plan.steps objectAtIndex:i];
            NSLog(@"%@   %@    %@", transitStep.entraceInstruction, transitStep.exitInstruction, transitStep.instruction);
            //轨迹点总数累计
            planPointCounts += transitStep.pointsCount;
        }

        int i = 0;
        NSMutableArray *points = [NSMutableArray arrayWithCapacity:planPointCounts];
        for (int j = 0; j < size; j++) {
            BMKWalkingStep* transitStep = [plan.steps objectAtIndex:j];
            int k=0;
            for(k=0;k<transitStep.pointsCount;k++) {

                CLLocationCoordinate2D transitStepCoord = BMKCoordinateForMapPoint(transitStep.points[k]);

                double latitude = transitStepCoord.latitude;
                double longitude = transitStepCoord.longitude;

                [points addObject:@{@"latitude":@(latitude),@"longitude":@(longitude)}];

                i++;
            }
        }
        body[@"dates"] = [NSString stringWithFormat:@"%d",plan.duration.dates];
        body[@"hours"] = [NSString stringWithFormat:@"%d",plan.duration.hours];
        body[@"minutes"] = [NSString stringWithFormat:@"%d",plan.duration.minutes];
        body[@"seconds"] = [NSString stringWithFormat:@"%d",plan.duration.seconds];
        body[@"distance"] = [NSString stringWithFormat:@"%d",plan.distance];
        body[@"points"] = points;
        body[@"count"] = [NSString stringWithFormat:@"%d", planPointCounts];


        _resolve(body);

    } else {
        body[@"errcode"] = [NSString stringWithFormat:@"%d", error];
        body[@"errmsg"] = [self getSearchErrorInfo:error];

        _reject(@"", @"", nil);
    }

}




-(CLLocationCoordinate2D)getCoorFromMarkerOption:(NSDictionary *)option {
    double lat = [RCTConvert double:option[@"latitude"]];
    double lng = [RCTConvert double:option[@"longitude"]];
    CLLocationCoordinate2D coor;
    coor.latitude = lat;
    coor.longitude = lng;
    return coor;
}


- (NSString *)getSearchErrorInfo:(BMKSearchErrorCode)error {
    NSString *errormsg = @"未知";
    switch (error) {
        case BMK_SEARCH_AMBIGUOUS_KEYWORD:
            errormsg = @"检索词有岐义";
            break;
        case BMK_SEARCH_AMBIGUOUS_ROURE_ADDR:
            errormsg = @"检索地址有岐义";
            break;
        case BMK_SEARCH_NOT_SUPPORT_BUS:
            errormsg = @"该城市不支持公交搜索";
            break;
        case BMK_SEARCH_NOT_SUPPORT_BUS_2CITY:
            errormsg = @"不支持跨城市公交";
            break;
        case BMK_SEARCH_RESULT_NOT_FOUND:
            errormsg = @"没有找到检索结果";
            break;
        case BMK_SEARCH_ST_EN_TOO_NEAR:
            errormsg = @"起终点太近";
            break;
        case BMK_SEARCH_KEY_ERROR:
            errormsg = @"key错误";
            break;
        case BMK_SEARCH_NETWOKR_ERROR:
            errormsg = @"网络连接错误";
            break;
        case BMK_SEARCH_NETWOKR_TIMEOUT:
            errormsg = @"网络连接超时";
            break;
        case BMK_SEARCH_PERMISSION_UNFINISHED:
            errormsg = @"还未完成鉴权，请在鉴权通过后重试";
            break;
        case BMK_SEARCH_INDOOR_ID_ERROR:
            errormsg = @"室内图ID错误";
            break;
        case BMK_SEARCH_FLOOR_ERROR:
            errormsg = @"室内图检索楼层错误";
            break;
        default:
            break;
    }
    return errormsg;
}

@end
