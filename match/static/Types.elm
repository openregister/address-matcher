module Types exposing (..)

import Http exposing (..)


type RemoteData error data
    = NotAsked
    | Loading
    | Success data
    | Failure error


type alias WebData data =
    RemoteData Http.Error data
