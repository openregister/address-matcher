module Rest exposing (..)

import Task exposing (perform)
import Http exposing (..)
import Json.Decode exposing (Decoder, (:=))
import List exposing (..)
import State exposing (..)
import User exposing (..)
import Address exposing (..)

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


testAddressDecoder : Decoder (List TestAddress)
testAddressDecoder =
    (Json.Decode.list
        (Json.Decode.object3 TestAddress
            ("name" := Json.Decode.string)
            ("address" := Json.Decode.string)
            ("id" := Json.Decode.int)
        )
    )


candidateAddressesDecoder : Decoder (List CandidateAddress)
candidateAddressesDecoder =
    (Json.Decode.list
        (Json.Decode.object5 CandidateAddress
            ("name" := Json.Decode.string)
            ("parent-address-name" := Json.Decode.string)
            ("street-name" := Json.Decode.string)
            ("street-town" := Json.Decode.string)
            ("uprn" := Json.Decode.string)
        )
    )


addCandidates : TestAddress -> Task.Task Error Address
addCandidates testAddress =
    let
        candidatesLookupUrl =
            url "/match/brain/" [ ( "q", testAddress.address ) ]
    in
        Task.map
            (\candidates -> (Address testAddress candidates))
            (fromJson candidateAddressesDecoder
                (send defaultSettings (jsonGet candidatesLookupUrl))
            )


fetchAddresses : Cmd Msg
fetchAddresses =
    let
        fetchTests : Task.Task Error (List TestAddress)
        fetchTests =
            (fromJson testAddressDecoder
                (send defaultSettings
                    (jsonGet ("/match/test-addresses/?n=5"))
                )
            )

        fetchAllCandidates : List TestAddress -> Task.Task Error (List Address)
        fetchAllCandidates testAddresses =
            Task.sequence (List.map addCandidates testAddresses)
    in
        Task.perform
            FetchAddressesFail
            FetchAddressesOk
            (fetchTests `Task.andThen` fetchAllCandidates)


sendMatch : String -> TestAddressId -> UserId -> Cmd Msg
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
