module Address exposing (..)

import List exposing (..)
import Types exposing (..)
import String exposing (..)

type alias TestId =
    Int

type alias Uprn =
    String

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
    , uprn : Uprn
    }


type alias Address =
    { test : Test
    , candidates : List Candidate
    }


type alias RemoteAddresses =
    WebData (List Address)


notSureCandidate: Candidate
notSureCandidate =
    Candidate "" "" "" "" "_notsure_"


noMatchCandidate: Candidate
noMatchCandidate =
    Candidate "" "" "" "" "_nomatch_"


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
            Success (List.filter (\a -> a.test.id /= testId) list)

        _ ->
            addresses
