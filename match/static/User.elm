module User
    exposing
        ( User
        , RemoteUsers
        , UserId
        , UserName
        , usersDecoder
        , id
        , name
        , score
        )

import Json.Decode exposing (..)
import Types exposing (WebData)
import List exposing (filter, head)


type alias UserId =
    Int


type alias UserName =
    String


type alias UserScore =
    Int


type alias UserRecord =
    { name : UserName
    , id : UserId
    , score : UserScore
    }


type User
    = User UserRecord


type alias RemoteUsers =
    WebData (List User)


findById : UserId -> List User -> Maybe User
findById userId users =
    filter (\user -> id user == userId) users
        |> head


id : User -> UserId
id (User u) =
    u.id


name : User -> UserName
name (User u) =
    u.name


score : User -> UserScore
score (User u) =
    u.score


userRecordDecoder : Decoder UserRecord
userRecordDecoder =
    map3 UserRecord
        (field "name" string)
        (field "id" int)
        (field "score" int)


userDecoder : Decoder User
userDecoder =
    oneOf
        [ map User userRecordDecoder ]


usersDecoder : Decoder (List User)
usersDecoder =
    list userDecoder
