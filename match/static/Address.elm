module Address exposing (..)

import List exposing (..)
import Types exposing (..)


type alias TestAddressId =
    Int


type alias TestAddress =
    { address : String
    , id : TestAddressId
    }


type alias CandidateAddress =
    { name : String
    , parentAddressName : String
    , streetName : String
    , streetTown : String
    , uprn : String
    }


type alias Address =
    { test : TestAddress
    , candidates : List CandidateAddress
    }


type alias RemoteAddresses =
    WebData (List Address)




removeAddress : TestAddressId -> RemoteAddresses -> RemoteAddresses
removeAddress testId addresses =
    case addresses of
        Success list ->
            Success (filter (\a -> a.test.id /= testId) list)

        _ ->
            addresses
