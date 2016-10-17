module State exposing (..)

import Http exposing (..)
import User exposing (..)
import Address exposing (..)
import Animation exposing (..)
import Animation.Messenger


-- Model
-- TODO: can we remove currentUserId and make the current user the top of the
-- users list?


type alias Model =
    { currentUserId : UserId
    , users : RemoteUsers
    , addresses : RemoteAddresses
    , animationStyle : Animation.Messenger.State Msg
    }


type Msg
    = FetchUsers
    | FetchUsersOk (List User)
    | FetchUsersFail Http.Error
    | UserChange String
    | FetchAddresses
    | FetchAddressesOk (List Address)
    | FetchAddressesFail Http.Error
    | NextCandidate ( Maybe String, TestAddressId )
    | SelectCandidate ( Maybe String, TestAddressId )
    | SendMatchFail Http.Error
    | SendMatchOk String
    | Animate Animation.Msg
