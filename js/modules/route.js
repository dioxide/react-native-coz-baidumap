// @flow
import { NativeModules } from 'react-native'
import type { LatLng } from '../types'

const { BaiduMapRoute } = NativeModules

type RouteResult = {
  count: number,
  dates: number,
  hours: number,
  minutes: number,
  seconds: number,
  duration: number,
  distance: number,
} & LatLng

export default {

  routePlanByCoordinate(startPoint: LatLng, endPoint: LatLng, type ) : Promise<RouteResult>  {
    return BaiduMapRoute.routePlanByCoordinate(startPoint, endPoint, type)
  },

}
