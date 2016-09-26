module State exposing (..)

import Http exposing (..)
import User exposing (..)
import Address exposing (..)


-- Model
-- TODO: can we remove currentUserId and make the current user the top of the
-- users list?


type alias Model =
    { currentUserId : UserId
    , users : RemoteUsers
    , addresses : RemoteAddresses
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
