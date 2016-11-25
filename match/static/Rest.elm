module Rest exposing (..)

import Task exposing (perform)
import Http exposing (..)
import Json.Decode exposing (Decoder)
import List exposing (..)
import Task exposing (andThen)
import State exposing (..)
import User exposing (..)
import Address exposing (..)
import DataSetInfo exposing (..)
import Stats exposing (..)


jsonGetRequest : String -> Decoder a -> Request a
jsonGetRequest url decoder =
    request
        { method = "GET"
        , headers = [ header "Accept" "application/json" ]
        , expect = expectJson decoder
        , url = url
        , body = emptyBody
        , timeout = Nothing
        , withCredentials = False
        }


fetchUsers : Cmd Msg
fetchUsers =
    send
        FetchUsersReturn
        (jsonGetRequest "/match/users/" User.usersDecoder)


fetchDataSetInfo : Cmd Msg
fetchDataSetInfo =
    send
        FetchDataSetInfoReturn
        (jsonGetRequest "/match/appinfo/" DataSetInfo.dataSetInfoDecoder)


testDecoder : Decoder (List Test)
testDecoder =
    (Json.Decode.list
        (Json.Decode.map3 Test
            (Json.Decode.field "name" Json.Decode.string)
            (Json.Decode.field "address" Json.Decode.string)
            (Json.Decode.field "id" Json.Decode.int)
        )
    )


candidateAddressesDecoder : Decoder (List Candidate)
candidateAddressesDecoder =
    (Json.Decode.list
        (Json.Decode.map5 Candidate
            (Json.Decode.field "name" Json.Decode.string)
            (Json.Decode.field "parent-address-name" Json.Decode.string)
            (Json.Decode.field "street-name" Json.Decode.string)
            (Json.Decode.field "street-town" Json.Decode.string)
            (Json.Decode.field "uprn" Json.Decode.string)
        )
    )


addCandidates : Test -> Task.Task Error Address
addCandidates test =
    let
        candidatesLookupUrl =
            "/match/brain/?q=" ++ (encodeUri test.address)
    in
        Task.map
            (\candidates -> (Address test candidates))
            (jsonGetRequest candidatesLookupUrl candidateAddressesDecoder
                |> toTask
            )


fetchAddresses : Cmd Msg
fetchAddresses =
    let
        fetchTests : Request (List Test)
        fetchTests =
            jsonGetRequest "/match/test-addresses/?n=5" testDecoder

        fetchAllCandidates : List Test -> Task.Task Error (List Address)
        fetchAllCandidates tests =
            Task.sequence (List.map addCandidates tests)
    in
        Task.attempt
            FetchAddressesReturn
            (fetchTests
                |> toTask
                |> andThen fetchAllCandidates
            )


sendMatch : String -> TestId -> UserId -> Cmd Msg
sendMatch uprn testId userId =
    let
        body =
            multipartBody
                [ stringPart "uprn" uprn
                , stringPart "test_address" (toString testId)
                , stringPart "user" (toString userId)
                ]

        request =
            post "/match/send/" body usersStatsDecoder
    in
        send SendMatchReturn request
