module User exposing
    (User, RemoteUsers, UserId, UserName, usersDecoder, id, name)

import Json.Decode exposing (Decoder, (:=))
import Types exposing (WebData)
import List exposing (..)


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
    Json.Decode.object2 UserRecord
        ("name" := Json.Decode.string)
        ("id" := Json.Decode.int)


userDecoder : Decoder User
userDecoder =
    Json.Decode.oneOf
        [ Json.Decode.map User userRecordDecoder ]


usersDecoder : Decoder (List User)
usersDecoder =
    Json.Decode.list userDecoder
