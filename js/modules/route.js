// @flow
import { NativeModules } from 'react-native'
import type { LatLng } from '../types'

const { BaiduMapRoute } = NativeModules

type SearchResult = { address: string } & LatLng

type ReverseResult = {
  country: string,
  countryCode: string,
  province: string,
  city: string,
  cityCode: string,
  district: string,
  street: string,
  streetNumber: string,
  businessCircle: string,
  adCode: string,
  address: string,
  description: string,
} & LatLng

export default {

  routPlanByCoordinate(startPoint: LatLng, endPoint: LatLng, type ) : Promise {
    return BaiduMapRoute.routPlanByCoordinate(startPoint, endPoint, type)
  },

}
