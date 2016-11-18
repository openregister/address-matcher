module Address exposing (..)

import List exposing (..)
import Types exposing (..)


type alias TestId =
    Int


type alias Test =
    { name : String
    , address : String
    , id : TestId
    }


type alias Candidate =
    { name : String
    , parentAddressName : String
    , streetName : String
    , streetTown : String
    , uprn : String
    }


type alias Address =
    { test : Test
    , candidates : List Candidate
    }


type alias RemoteAddresses =
    WebData (List Address)


remoteAddressCount : RemoteAddresses -> Int
remoteAddressCount remoteAddresses =
    case remoteAddresses of
        Success list ->
            List.length list

        _ ->
            0


removeAddress : TestId -> RemoteAddresses -> RemoteAddresses
removeAddress testId addresses =
    case addresses of
        Success list ->
            Success (filter (\a -> a.test.id /= testId) list)

        _ ->
            addresses
