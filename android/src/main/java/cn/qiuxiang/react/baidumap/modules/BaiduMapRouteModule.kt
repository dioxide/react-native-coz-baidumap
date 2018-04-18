package cn.qiuxiang.react.baidumap.modules

import cn.qiuxiang.react.baidumap.toLatLng
import com.baidu.mapapi.model.LatLng
import com.baidu.mapapi.search.core.SearchResult
import com.baidu.mapapi.search.route.*
import com.facebook.react.bridge.*


@Suppress("unused")
class BaiduMapRouteModule(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    private var promise: Promise? = null
    private val routeSearcher by lazy {
        val routeSearcher = RoutePlanSearch.newInstance();
        routeSearcher.setOnGetRoutePlanResultListener(object : OnGetRoutePlanResultListener {

            override fun onGetWalkingRouteResult(result: WalkingRouteResult) {


                if (result == null || result.error != SearchResult.ERRORNO.NO_ERROR) {

                    promise?.reject("", "检索失败")

                } else {

                    try {

                        val data = Arguments.createMap()

                        val routeLines = result.getRouteLines();//所有路线

                        val planLine: WalkingRouteLine = routeLines[0];

                        val walkingSteps = planLine.allStep

                        //路线信息
                        data.putInt("count", walkingSteps.size)
                        data.putInt("dates", 0)
                        data.putInt("hours", 0)
                        data.putInt("minutes", 0)
                        data.putInt("seconds", 0)
                        data.putInt("duration", planLine.duration)
                        data.putInt("distance", planLine.distance)


                        //路径点集合
                        val planLinePoints = Arguments.createArray()


                        for ((index, step: WalkingRouteLine.WalkingStep) in walkingSteps.withIndex()) {

                            val direction = step.direction;
                            val entrance = step.entrance;
                            var entranceInstructions = step.entranceInstructions;
                            val exit = step.exit;
                            val instructions = step.instructions
                            val wayPoints = step.wayPoints

                            //println("路段: 方向 $direction, 进入 $entrance, 描述 $instructions, 终点 $exit, $wayPoints ")

                            for ((index, point: LatLng) in wayPoints.withIndex()) {

                                val pointCoord = Arguments.createMap();

                                pointCoord.putDouble("latitude", point.latitude)
                                pointCoord.putDouble("longitude", point.longitude)

                                planLinePoints.pushMap(pointCoord)

                            }

                        }

                        data.putArray("points", planLinePoints)

                        promise?.resolve(data)

                    }
                    catch (e: Exception) {
                        promise?.reject("", "路线数据解析失败")
                    }
                }
            }

            override fun onGetTransitRouteResult(result: TransitRouteResult) {

            }

            override fun onGetMassTransitRouteResult(result: MassTransitRouteResult) {

            }

            override fun onGetDrivingRouteResult(result: DrivingRouteResult) {

            }

            override fun onGetIndoorRouteResult(result: IndoorRouteResult) {

            }

            override fun onGetBikingRouteResult(result: BikingRouteResult) {

            }


        })
        routeSearcher

    }

    override fun getName(): String {
        return "BaiduMapRoute"
    }

    override fun canOverrideExistingModule(): Boolean {
        return true
    }

    @ReactMethod
    fun routePlanByCoordinate(starPoint: ReadableMap, endPoint: ReadableMap, routeType: Int, promise: Promise) {
        this.promise = promise

        val stNode = PlanNode.withLocation(starPoint.toLatLng());
        val enNode = PlanNode.withLocation(endPoint.toLatLng());

        routeSearcher.walkingSearch(WalkingRoutePlanOption().from(stNode).to(enNode));

    }

}
