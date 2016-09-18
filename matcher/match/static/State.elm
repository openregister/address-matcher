module State exposing (..)

import Http exposing (..)
import List exposing (..)



type alias User =
    { name : String
    , id : Int
    }


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


type alias Model =
    { error : Maybe Error
    , currentUserId : Int
    , users : List User
    , addresses : List Address
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
    | SendMatchFail Http.Error
    | SendMatchOk String


-- Model transformation functions


removeAddress : Int -> List Address -> List Address
removeAddress testId list =
    filter (\a -> a.test.id /= testId) list

