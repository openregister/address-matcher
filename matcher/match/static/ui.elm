module Ui exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.App as App
import Task exposing (perform)
import Http exposing (..)
import Json.Decode exposing (Decoder, (:=))
import List exposing (..)


main =
    App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias User =
    { name : String
    , url : String
    }


type alias Model =
    { currentUserUri : String
    , users : List User
    }


init : ( Model, Cmd Msg )
init =
    ( { currentUserUri = "", users = [] }, fetchUsers )



-- HTTP


fetchUsers : Cmd Msg
fetchUsers =
    Task.perform
        FetchUsersFail
        FetchUsersOk
        (Http.get (Json.Decode.list userDecoder) "/match/users/")


userDecoder : Decoder User
userDecoder =
    (Json.Decode.object2 User
        ("name" := Json.Decode.string)
        ("url" := Json.Decode.string)
    )



-- UPDATE


type Msg
    = FetchUsers
    | FetchUsersOk (List User)
    | FetchUsersFail Http.Error
    | UserChange String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchUsers ->
            ( model, fetchUsers )

        FetchUsersOk users ->
            ( { model | users = users }, Cmd.none )

        FetchUsersFail error ->
            ( model, Cmd.none )

        UserChange userUri ->
            ( { model | currentUserUri = userUri }, Cmd.none )



-- VIEW


userOption : User -> Html Msg
userOption user =
    option [ value user.url ] [ text user.name ]


usersDropdown : List User -> Html Msg
usersDropdown users =
    select [ onInput UserChange ]
        ((option [] [ text "Select a user" ]) :: (map userOption users))


view : Model -> Html Msg
view model =
    div []
        [ usersDropdown model.users
        , div [] [ text (toString model) ]
        ]
