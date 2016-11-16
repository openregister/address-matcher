module User exposing
    (User, RemoteUsers, UserId, UserName, usersDecoder, id, name)

import Json.Decode exposing (..)
import Types exposing (WebData)
import List exposing (filter, head)


type alias UserId =
    Int


type alias UserName =
    String


type alias UserRecord =
    { name : UserName
    , id : UserId
    }


type User =
    User UserRecord


type alias RemoteUsers =
    WebData (List User)


findById : UserId -> List User -> Maybe User
findById userId users =
    filter (\user -> id user == userId) users
        |> head


id : User -> UserId
id (User { id, name }) =
    id


name : User -> UserName
name (User { id, name }) =
    name


userRecordDecoder : Decoder UserRecord
userRecordDecoder =
    map2 UserRecord
        (field "name" string)
        (field "id" int)


userDecoder : Decoder User
userDecoder =
    oneOf
        [ map User userRecordDecoder ]


usersDecoder : Decoder (List User)
usersDecoder =
    list userDecoder
