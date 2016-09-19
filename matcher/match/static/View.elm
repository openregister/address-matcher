module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import List exposing (..)

import State exposing (..)


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
            [ p [ class "heading-medium" ] [(address.test.address) |> text]
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
error err =
    case err of
        Nothing ->
            div [] []
        Just message ->
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
