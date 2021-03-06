module Main exposing (..)

import String exposing (toInt)
import Navigation exposing (Location)
import UrlParser exposing (..)
import Animation exposing (px)
import Animation.Messenger
import State exposing (..)
import View
import Rest
import Types exposing (..)
import User exposing (..)
import Address exposing (..)


main : Program Never Model Msg
main =
    Navigation.program
        locationMessage
        { init = init
        , view = View.view
        , update = update
        , subscriptions = subscriptions
        }


locationMessage : Location -> Msg
locationMessage location =
    UrlChange location



-- INIT


init : Location -> ( Model, Cmd Msg )
init location =
    let
        userId =
            userIdFromLocation location

        initCmd =
            if userId == 0 then
                [ Rest.fetchDataSetInfo
                , Rest.fetchUsers ]
            else
                [ Rest.fetchDataSetInfo
                , Rest.fetchUsers
                , Rest.fetchAddressesForUser userId
                ]

        initialAnimationStyle =
            Animation.style [ Animation.left (px 0) ]
    in
        (Model userId Loading NotAsked Loading initialAnimationStyle 0)
            ! initCmd


userIdFromLocation : Location -> UserId
userIdFromLocation location =
    parseHash (s "userId" </> int) location
        |> Maybe.withDefault 0



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription Animate [ model.animationStyle ]



-- Page URL Stuff


userIdToUrl : UserId -> String
userIdToUrl userId =
    "#userId/" ++ (toString userId)


updateUrl : UserId -> Cmd Msg
updateUrl userId =
    Navigation.newUrl (userIdToUrl userId)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            ( { model | currentUserId = userIdFromLocation location }
            , Cmd.none
            )

        FetchUsers ->
            ( { model | users = Loading }, Rest.fetchUsers )

        FetchUsersReturn (Ok newUserList) ->
            ( { model | users = Success newUserList }, Cmd.none )

        FetchUsersReturn (Err error) ->
            ( { model | users = Failure error }, Cmd.none )

        UserChange newUserIdAsText ->
            let
                newUserId =
                    newUserIdAsText |> toInt |> Result.withDefault 0
            in
                { model | currentUserId = newUserId } !
                    [ updateUrl newUserId
                    , Rest.fetchAddressesForUser newUserId
                    ]

        FetchDataSetInfo ->
            ( { model | dataSetInfo = Loading }, Rest.fetchDataSetInfo )

        FetchDataSetInfoReturn (Ok newDataSetInfo) ->
            ( { model | dataSetInfo = Success newDataSetInfo }, Cmd.none )

        FetchDataSetInfoReturn (Err error) ->
            ( { model | dataSetInfo = Failure error }, Cmd.none )

        FetchAddresses ->
            ( { model | addresses = Loading }
            , Rest.fetchAddressesForUser model.currentUserId
            )

        FetchAddressesReturn (Ok newAddresses) ->
            ( { model | addresses = Success newAddresses }, Cmd.none )

        FetchAddressesReturn (Err error) ->
            ( { model | addresses = Failure error }, Cmd.none )

        SelectCandidate ( candidate, testId ) ->
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
                            ( candidate, testId )
                        )
                    , animationReset
                    ]
            in
                ( { model
                    | animationStyle =
                        (Animation.interrupt animation model.animationStyle)
                  }
                , Cmd.none
                )

        NextCandidate ( candidate, testId ) ->
            let
                newModel =
                    { model | addresses = removeAddress testId model.addresses }

                sendMatchCmd : Cmd Msg
                sendMatchCmd =
                    Rest.sendMatch
                        candidate
                        testId
                        model.currentUserId
            in
                ( newModel, sendMatchCmd )

        SendMatchReturn (Ok usersStats) ->
            let
                newModel1 =
                    { model | users = Success usersStats.users }

                newModel =
                    { newModel1 | lastMatchScore = usersStats.lastMatchScore }
            in
                ( newModel, Cmd.none )

        SendMatchReturn (Err error) ->
            ( model, Cmd.none )

        Animate animMsg ->
            let
                ( newStyle, cmds ) =
                    Animation.Messenger.update
                        animMsg
                        model.animationStyle
            in
                ( { model | animationStyle = newStyle }, cmds )
