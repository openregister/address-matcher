port module Main exposing (..)

import String exposing (toInt)
import Navigation
import Animation exposing (px)
import Animation.Messenger
import State exposing (..)
import View
import Rest
import Maybe
import Types exposing (..)
import User exposing (..)
import Address exposing (..)



main : Program Never
main =
    Navigation.program urlParser
        { init = init
        , view = View.view
        , update = update
        , subscriptions = subscriptions
        , urlUpdate = urlUpdate
        }



-- PORTS

port scrollTop : String -> Cmd msg


-- INIT


init : Result String UserId -> ( Model, Cmd Msg )
init result =
    let
        userId =
            Result.withDefault 0 result

        initCmd =
            if userId == 0 then
                [ Rest.fetchUsers ]
            else
                [ Rest.fetchUsers, Rest.fetchAddresses ]

        initialAnimationStyle =
            Animation.style [ Animation.left (px 0) ]
    in
        (Model userId Loading NotAsked initialAnimationStyle) ! initCmd



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription Animate [ model.animationStyle ]



-- Page URL Stuff


userIdToUrl : UserId -> String
userIdToUrl userId =
    "#" ++ (toString userId)


updateUrl : UserId -> Cmd Msg
updateUrl userId =
    Navigation.newUrl (userIdToUrl userId)


fromUrl : String -> Result String UserId
fromUrl url =
    String.toInt (String.dropLeft 1 url)


urlParser : Navigation.Parser (Result String UserId)
urlParser =
    Navigation.makeParser (fromUrl << .hash)


urlUpdate : Result String UserId -> Model -> ( Model, Cmd Msg )
urlUpdate result model =
    case result of
        Ok newUserId ->
            ( { model | currentUserId = newUserId }, Cmd.none )

        Err _ ->
            ( model
            , Navigation.modifyUrl (userIdToUrl model.currentUserId)
            )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchUsers ->
            ( { model | users = Loading }
            , Rest.fetchUsers
            )

        FetchUsersOk newUserList ->
            ( { model | users = Success newUserList }, Cmd.none )

        FetchUsersFail error ->
            ( { model | users = Failure error }, Cmd.none )

        UserChange newUserIdAsText ->
            let
                newUserId =
                    newUserIdAsText |> toInt |> Result.withDefault 0
            in
                { model | currentUserId = newUserId }
                    ! [ updateUrl newUserId, Rest.fetchAddresses ]

        FetchAddresses ->
            ( { model | addresses = Loading }, Rest.fetchAddresses )

        FetchAddressesOk newAddresses ->
            ( { model | addresses = Success newAddresses }, Cmd.none )

        FetchAddressesFail error ->
            ( { model | addresses = Failure error }, Cmd.none )

        SelectCandidate ( selectedCandidateUprn, testId ) ->
            let
                animationMoveLeft =
                    Animation.toWith
                        (Animation.speed { perSecond = 8000 })
                        [ Animation.left (px -3000) ]

                animationReset =
                    Animation.set [ Animation.left (px 0) ]

                animation =
                        [ animationMoveLeft
                        , Animation.Messenger.send
                            (NextCandidate
                                    ( selectedCandidateUprn, testId ))
                        , animationReset
                        ]
            in
                ( { model | animationStyle =
                        (Animation.interrupt animation model.animationStyle) }
                , scrollTop "notused"
                )

        NextCandidate ( selectedCandidateUprn, testId ) ->
            let
                command =
                    case selectedCandidateUprn of
                        Nothing ->
                            Cmd.none

                        Just uprn ->
                            Rest.sendMatch
                                uprn
                                testId
                                model.currentUserId
            in
                ( { model
                    | addresses = removeAddress testId model.addresses
                }
                , command
                )

        SendMatchOk result ->
            ( model, Cmd.none )

        SendMatchFail error ->
            ( model, Cmd.none )

        Animate animMsg ->
            let
                ( newStyle, cmds ) =
                    Animation.Messenger.update
                        animMsg
                        model.animationStyle
            in
                ( { model | animationStyle = newStyle }, cmds )
