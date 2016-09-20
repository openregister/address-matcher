module Main exposing (..)

import Html.App as App
import String exposing (toInt)

import State exposing (..)
import View
import Rest



main : Program Never
main =
    App.program
        { init = init
        , view = View.view
        , update = update
        , subscriptions = always Sub.none
        }



-- INIT


init : ( Model, Cmd Msg )
init =
    (Model Nothing 0 [] []) ! [ Rest.fetchUsers ]




-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchUsers ->
            ( model, Rest.fetchUsers )

        FetchUsersOk users ->
            ( { model | users = users }, Cmd.none )

        FetchUsersFail error ->
            ( { model | error = Just error }, Cmd.none )

        UserChange newUserId ->
            let
                newUserIdAsInt = newUserId |> toInt |> Result.withDefault 0
            in
                ( { model | currentUserId = newUserIdAsInt }
                , Rest.fetchAddresses
                )

        FetchAddresses ->
            ( model, Rest.fetchAddresses )

        FetchAddressesOk addresses ->
            ( { model | addresses = addresses }, Cmd.none )

        FetchAddressesFail error ->
            ( { model | error = Just error }, Cmd.none )

        SelectCandidate ( selectedCandidateUprn, testId ) ->
            ( { model | addresses = removeAddress testId model.addresses }
            , Rest.sendMatch selectedCandidateUprn testId model.currentUserId
            )

        NoMatch testId ->
            ( { model | addresses = removeAddress testId model.addresses }
            , Cmd.none
            )

        SendMatchOk result ->
            ( model, Cmd.none )

        SendMatchFail error ->
            ( { model | error = Just error }, Cmd.none )
