module Rest exposing (..)

import Task exposing (perform)
import Http exposing (..)
import Json.Decode exposing (Decoder, (:=))
import List exposing (..)
import State exposing (..)
import User exposing (..)
import DataSetInfo exposing (..)
import Address exposing (..)
import Task exposing (andThen)

jsonGet : String -> Request
jsonGet url =
    { verb = "GET"
    , headers = [ ( "Accept", "application/json" ) ]
    , url = url
    , body = Http.empty
    }


fetchUsers : Cmd Msg
fetchUsers =
    Task.perform
        FetchUsersFail
        FetchUsersOk
        (fromJson usersDecoder
            (send defaultSettings (jsonGet ("/match/users/")))
        )


fetchDataSetInfo : Cmd Msg
fetchDataSetInfo =
    let
        getInfoAsList =
            (fromJson dataSetInfoDecoder
                 (send defaultSettings (jsonGet ("/match/appinfo/")))
            )
    in
        Task.perform
            FetchDataSetInfoFail
            FetchDataSetInfoOk
            getInfoAsList


testDecoder : Decoder (List Test)
testDecoder =
    (Json.Decode.list
        (Json.Decode.object3 Test
            ("name" := Json.Decode.string)
            ("address" := Json.Decode.string)
            ("id" := Json.Decode.int)
        )
    )


candidateAddressesDecoder : Decoder (List Candidate)
candidateAddressesDecoder =
    (Json.Decode.list
        (Json.Decode.object5 Candidate
            ("name" := Json.Decode.string)
            ("parent-address-name" := Json.Decode.string)
            ("street-name" := Json.Decode.string)
            ("street-town" := Json.Decode.string)
            ("uprn" := Json.Decode.string)
        )
    )


addCandidates : Test -> Task.Task Error Address
addCandidates test =
    let
        candidatesLookupUrl =
            url "/match/brain/" [ ( "q", test.address ) ]
    in
        Task.map
            (\candidates -> (Address test candidates))
            (fromJson candidateAddressesDecoder
                (send defaultSettings (jsonGet candidatesLookupUrl))
            )


fetchAddresses : Cmd Msg
fetchAddresses =
    let
        fetchTests : Task.Task Error (List Test)
        fetchTests =
            (fromJson testDecoder
                (send defaultSettings
                    (jsonGet ("/match/test-addresses/?n=5"))
                )
            )

        fetchAllCandidates : List Test -> Task.Task Error (List Address)
        fetchAllCandidates tests =
            Task.sequence (List.map addCandidates tests)
    in
        Task.perform
            FetchAddressesFail
            FetchAddressesOk
            (fetchTests `Task.andThen` fetchAllCandidates)


sendMatch : String -> TestId -> UserId -> Cmd Msg
sendMatch uprn testId userId =
    let
        body =
            multipart
                [ stringData "uprn" uprn
                , stringData "test_address" (toString testId)
                , stringData "user" (toString userId)
                ]
    in
        Task.perform
            SendMatchFail
            SendMatchOk
            (post (Json.Decode.succeed "") "/match/matches/" body)
