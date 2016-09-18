module Ui exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App
import Task exposing (perform)
import Http exposing (..)
import Json.Decode exposing (Decoder, (:=))
import List exposing (..)
import String exposing (toInt)


main : Program Never
main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


apiUrl : String
apiUrl =
    "http://localhost:8000"



-- MODEL


type alias User =
    { name : String
    , id : Int
    }


type alias TestAddress =
    { address : String
    , id : Int
    }


type alias CandidateAddress =
    { address : String
    , uprn : String
    }


type alias Address =
    { test : TestAddress
    , candidates : List CandidateAddress
    }


type alias Model =
    { error : Maybe Error
    , currentUserId : Int
    , users : List User
    , addresses : List Address
    }



-- Model transformation functions


removeAddress : Int -> List Address -> List Address
removeAddress testId list =
    filter (\a -> a.test.id /= testId) list



-- INIT


init : ( Model, Cmd Msg )
init =
    (Model Nothing 0 [] []) ! [ fetchUsers, fetchAddresses ]



-- HTTP


jsonGet : String -> Request
jsonGet url =
    { verb = "GET"
    , headers = [ ( "Accept", "application/json" ) ]
    , url = url
    , body = empty
    }


fetchUsers : Cmd Msg
fetchUsers =
    Task.perform
        FetchUsersFail
        FetchUsersOk
        (fromJson usersDecoder
            (send defaultSettings (jsonGet (apiUrl ++ "/match/users/")))
        )


usersDecoder : Decoder (List User)
usersDecoder =
    (Json.Decode.list
        (Json.Decode.object2 User
            ("name" := Json.Decode.string)
            ("id" := Json.Decode.int)
        )
    )


testAddressDecoder : Decoder (List TestAddress)
testAddressDecoder =
    (Json.Decode.list
        (Json.Decode.object2 TestAddress
            ("address" := Json.Decode.string)
            ("id" := Json.Decode.int)
        )
    )


candidateAddressesDecoder : Decoder (List CandidateAddress)
candidateAddressesDecoder =
    (Json.Decode.list
        (Json.Decode.object2 CandidateAddress
            ("address" := Json.Decode.string)
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
                    (jsonGet (apiUrl ++ "/match/test-addresses/?n=5"))
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


sendMatch : String -> Int -> Int -> Cmd Msg
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
            (post (Json.Decode.succeed "") (apiUrl ++ "/match/matches/") body)



-- UPDATE


type Msg
    = FetchUsers
    | FetchUsersOk (List User)
    | FetchUsersFail Http.Error
    | UserChange String
    | FetchAddresses
    | FetchAddressesOk (List Address)
    | FetchAddressesFail Http.Error
    | SelectCandidate ( String, Int )
    | SendMatchFail Http.Error
    | SendMatchOk String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchUsers ->
            ( model, fetchUsers )

        FetchUsersOk users ->
            ( { model | users = users }, Cmd.none )

        FetchUsersFail error ->
            ( { model | error = Just error }, Cmd.none )

        UserChange newUserId ->
            let
                newUserIdAsInt = newUserId |> toInt |> Result.withDefault 0
            in
                ( { model | currentUserId = newUserIdAsInt }, Cmd.none )

        FetchAddresses ->
            ( model, fetchAddresses )

        FetchAddressesOk addresses ->
            ( { model | addresses = addresses }, Cmd.none )

        FetchAddressesFail error ->
            ( { model | error = Just error }, Cmd.none )

        SelectCandidate ( selectedCandidateUprn, testId ) ->
            ( { model | addresses = removeAddress testId model.addresses }
            , sendMatch selectedCandidateUprn testId model.currentUserId
            )

        SendMatchOk result ->
            ( model, Cmd.none )

        SendMatchFail error ->
            ( { model | error = Just error }, Cmd.none )



-- VIEW


candidate : ( CandidateAddress, Int ) -> Html Msg
candidate candidate =
    let
        candidateAddress =
            fst candidate

        testId =
            snd candidate
    in
        li []
            [ input
                [ type' "button"
                , value " "
                , onClick (SelectCandidate ( candidateAddress.uprn, testId ))
                ]
                []
            , text (" " ++ candidateAddress.address)
            , small [] [ text (" " ++ candidateAddress.uprn) ]
            ]


address : Address -> Html Msg
address address =
    let
        addTestId : CandidateAddress -> ( CandidateAddress, Int )
        addTestId ca =
            ( ca, address.test.id )
    in
        li []
            [ (address.test.address) |> text
            , ul [] (map candidate (map addTestId address.candidates))
            ]


addresses : List Address -> Html Msg
addresses addresses =
    ul [] (map address addresses)


userOption : User -> Html Msg
userOption user =
    option [ value (toString user.id) ] [ text user.name ]


usersDropdown : List User -> Html Msg
usersDropdown users =
    select [ onInput UserChange ]
        ((option [] [ text "Select a user" ]) :: (map userOption users))


error : Maybe Error -> Html Msg
error message =
    div [] [ text (toString message) ]


view : Model -> Html Msg
view model =
    let
        addressSection =
            if model.currentUserId == 0 then
                p [] [ text "Please select a user" ]
            else
                addresses model.addresses
    in
        div []
            [ error model.error
            , usersDropdown model.users
            , addressSection
              -- , div [] [ text (toString model) ]
            ]
