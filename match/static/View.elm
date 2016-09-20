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
            , text " "
            , small [] [ a [ href ("https://www.google.com/maps/embed/v1/place?key=AIzaSyAJTbvZlhyNCaRDef08HD-OYC_CTPwk2Vc&q=" ++ candidateAddress.address), target "_blank" ] [ text "check on map" ] ]
            ]


address : Address -> Html Msg
address address =
    let
        addTestId : CandidateAddress -> ( CandidateAddress, Int )
        addTestId ca =
            ( ca, address.test.id )
        notSureChoice = li []
            [ input
                [ type' "button"
                , value " "
                , onClick (NoMatch address.test.id)
                ] []
            , text " Pass ¯\\_(ツ)_/¯"
            ]
    in
        li []
            [ p [ class "heading-medium" ] [(address.test.address) |> text]
            , ul []
                (notSureChoice ::
                    (map candidate (map addTestId address.candidates))
                )
            ]


addresses : List Address -> Html Msg
addresses addresses =
    ul [] (map address addresses)


userOption : Int -> User -> Html Msg
userOption currentUserId user =
    option
        [ value (toString user.id), selected (user.id == currentUserId) ]
        [ text user.name ]


usersDropdown : Int -> List User -> Html Msg
usersDropdown currentUserId users =
    select [ onInput UserChange ]
        ((option [] [ text "Select a user" ]) ::
            (map (userOption currentUserId) users)
        )


error : Maybe Error -> Html Msg
error err =
    case err of
        Nothing ->
            div [] []

        Just message ->
            div [] [ text (toString message) ]

embeddedMap : String -> Html Msg
embeddedMap search =
    iframe
        [ width 400
        , height 400
        , Html.Attributes.style [("border", "0")]
        , src ("https://www.google.com/maps/embed/v1/place?key=AIzaSyAJTbvZlhyNCaRDef08HD-OYC_CTPwk2Vc&q=" ++ search)
        ] []


view : Model -> Html Msg
view model =
    let
        addressSection =
            if model.currentUserId == 0 then
                p [] [ text "Please tell me who you are" ]
            else
                addresses model.addresses
    in
        div []
            [ error model.error
            , usersDropdown model.currentUserId model.users
            -- , embeddedMap "51.638514,-0.467906"
            , addressSection
              -- , div [] [ text (toString model) ]
            ]
