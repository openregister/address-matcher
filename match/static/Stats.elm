module Stats exposing (..)

import Json.Decode exposing (..)
import Types exposing (WebData)


type alias RemoteStats =
    WebData Stats


type Stats
    = Stats StatsRecord


users : Stats -> List UserStats
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


type alias UserStats =
    { nbMatches : Int
    , score : Int
    , userId : Int
    , name : String
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
    , users : List UserStats
    , occurrences : List Occurrence
    }



{-
   {
     "nb_pass_ratio": 3.0,
     "users": [{
       "nb_matches": 35,
       "score": 35,
       "user_id": 5,
       "name": "Gemma"
     }, {
       "nb_matches": 3,
       "score": 3,
       "user_id": 7,
       "name": "Olivia"
     }],
     "nb_addresses": 63,
     "nb_matches": 38,
     "occurrences": [
       ["Addresses not matched", 27],
       ["Addresses matched once", 34],
       ["Addresses matched twice", 2]
     ],
     "nb_pass": 1
   }
-}


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
        (field "users" (list userStatsDecoder))
        (field "occurrences" (list occurrenceDecoder))


occurrenceDecoder : Decoder Occurrence
occurrenceDecoder =
    map2
        Occurrence
        (index 0 string)
        (index 1 int)


userStatsDecoder : Decoder UserStats
userStatsDecoder =
    map4
        UserStats
        (field "nb_matches" int)
        (field "score" int)
        (field "user_id" int)
        (field "name" string)
