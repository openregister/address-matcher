module State exposing (..)

import Http exposing (..)
import List exposing (..)


type RemoteData error data
    = NotAsked
    | Loading
    | Success data
    | Failure error


type alias WebData data =
    RemoteData Http.Error data



-- User types


type alias UserId =
    Int


type alias User =
    { name : String
    , id : UserId
    }



-- Address types


type alias TestAddressId =
    Int


type alias TestAddress =
    { address : String
    , id : TestAddressId
    }


type alias CandidateAddress =
    { address : String
    , uprn : String
    }


type alias Address =
    { test : TestAddress
    , candidates : List CandidateAddress
    }


type alias Addresses =
    WebData (List Address)


type alias Users =
    WebData (List User)



-- Model


type alias Model =
    { currentUserId : UserId
    , users : Users
    , addresses : Addresses
    }


type Msg
    = FetchUsers
    | FetchUsersOk (List User)
    | FetchUsersFail Http.Error
    | UserChange String
    | FetchAddresses
    | FetchAddressesOk (List Address)
    | FetchAddressesFail Http.Error
    | SelectCandidate ( String, TestAddressId )
    | NoMatch TestAddressId
    | SendMatchFail Http.Error
    | SendMatchOk String



-- Model transformation functions


removeAddress : UserId -> Addresses -> Addresses
removeAddress testId addresses =
    case addresses of
        Success list ->
            Success (filter (\a -> a.test.id /= testId) list)

        _ ->
            addresses
