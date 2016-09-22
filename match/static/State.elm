module State exposing (..)

import Http exposing (..)
import List exposing (..)


type RemoteData error data
    = NotAsked
    | Loading
    | Success data
    | Failure error



-- User types


type alias User =
    { name : String
    , id : Int
    }



-- Address types


type alias TestAddress =
    { address : String
    , id : Int
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
    RemoteData Http.Error (List Address)


type alias Users =
    RemoteData Http.Error (List User)



-- Model


type alias Model =
    { currentUserId : Int
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
    | SelectCandidate ( String, Int )
    | NoMatch Int
    | SendMatchFail Http.Error
    | SendMatchOk String



-- Model transformation functions


removeAddress : Int -> Addresses -> Addresses
removeAddress testId addresses =
    case addresses of
        Success list ->
            Success (filter (\a -> a.test.id /= testId) list)

        _ ->
            addresses
