module DataSetInfo exposing (..)

import Json.Decode exposing (Decoder, (:=))
import Dict exposing (..)
import Types exposing (WebData)

type alias DataSetInfoRecord =
    Dict String String


type DataSetInfo =
    DataSetInfo DataSetInfoRecord


type alias RemoteDataSetInfo =
    WebData DataSetInfo


dataSetInfoDecoder : Decoder DataSetInfo
dataSetInfoDecoder =
    Json.Decode.map (Dict.fromList >> DataSetInfo) dataSetAsListDecoder



dataSetAsListDecoder : Decoder (List (String, String))
dataSetAsListDecoder =
    Json.Decode.list
        (Json.Decode.object2 (,)
             ("key" := Json.Decode.string)
             ("value" := Json.Decode.string)
        )

get : String -> DataSetInfo -> Maybe String
get key (DataSetInfo info) =
    Dict.get key info
