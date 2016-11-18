module State exposing (..)

import Http exposing (..)
import Navigation exposing (Location)
import User exposing (..)
import DataSetInfo exposing (..)
import Address exposing (..)
import Animation exposing (..)
import Animation.Messenger
import Stats exposing (RemoteStats, Stats)


-- Model
-- TODO: can we remove currentUserId and make the current user the top of the
-- users list?


type alias Model =
    { currentUserId : UserId
    , users : RemoteUsers
    , addresses : RemoteAddresses
    , dataSetInfo : RemoteDataSetInfo
    , animationStyle : Animation.Messenger.State Msg
    , stats : RemoteStats
    }


type Msg
    = UrlChange Location
    | FetchUsers
    | FetchUsersReturn (Result Http.Error (List User))
    | FetchDataSetInfo
    | FetchDataSetInfoReturn (Result Http.Error DataSetInfo)
    | FetchStatsReturn (Result Http.Error Stats)
    | FetchAddresses
    | FetchAddressesReturn (Result Http.Error (List Address))
    | UserChange String
    | NextCandidate ( String, TestId )
    | SelectCandidate ( String, TestId )
    | SendMatchReturn (Result Http.Error String)
    | Animate Animation.Msg
