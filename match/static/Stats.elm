module Stats exposing (..)

import Json.Decode exposing (..)
import Types exposing (WebData)
import User exposing (User, usersDecoder)

type alias RemoteStats =
    WebData Stats


type Stats
    = Stats StatsRecord


users : Stats -> List User
users (Stats s) =
    s.users


nbPassRatio : Stats -> Float
nbPassRatio (Stats s) =
    s.nbPassRatio


occurrences : Stats -> List Occurrence
occurrences (Stats s) =
    s.occurrences


nbPass : Stats -> Int
nbPass (Stats s) =
    s.nbPass


nbMatches : Stats -> Int
nbMatches (Stats s) =
    s.nbMatches


nbAddresses : Stats -> Int
nbAddresses (Stats s) =
    s.nbAddresses


type alias UsersStats =
    { lastMatchScore : Int
    , users : List User.User
    }


type alias Occurrence =
    { typeOfOccurrence : String
    , occurrenceValue : Int
    }


type alias StatsRecord =
    { nbPassRatio : Float
    , nbMatches : Int
    , nbAddresses : Int
    , nbPass : Int
    , users : List User
    , occurrences : List Occurrence
    }




statsDecoder : Decoder Stats
statsDecoder =
    oneOf
        [ map Stats statsRecordDecoder ]


statsRecordDecoder : Decoder StatsRecord
statsRecordDecoder =
    map6
        StatsRecord
        (field "nb_pass_ratio" float)
        (field "nb_matches" int)
        (field "nb_addresses" int)
        (field "nb_pass" int)
        (field "users" User.usersDecoder)
        (field "occurrences" (list occurrenceDecoder))


occurrenceDecoder : Decoder Occurrence
occurrenceDecoder =
    map2
        Occurrence
        (index 0 string)
        (index 1 int)


usersStatsDecoder : Decoder UsersStats
usersStatsDecoder =
    map2
        UsersStats
        (field "last_match_score" int)
        (field "users" User.usersDecoder)
