module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import List exposing (..)

import State exposing (..)


searchUrl : String -> String
searchUrl search =
    url "https://www.google.co.uk/search"
        [ ("q", search) ]

mapUrl : String -> String
mapUrl search =
    url "https://www.google.com/maps/embed/v1/place"
        [ ( "key", "AIzaSyAJTbvZlhyNCaRDef08HD-OYC_CTPwk2Vc" ), ("q", search) ]


candidate : ( CandidateAddress, Int ) -> Html Msg
candidate candidate =
    let
        candidateAddress =
            fst candidate

        testId =
            snd candidate
    in
        li [ style [ ("text-indent", "-20px" ) ] ]
            [ input
                [ type' "button"
                , value " "
                , onClick (SelectCandidate ( candidateAddress.uprn, testId ))
                ]
                []
            , text (" " ++ candidateAddress.address)
            , text " "
            , small []
                [ a [ href (mapUrl candidateAddress.address)
                , target "_blank"
                ]
                [ text "map⧉" ] ]
            ]

address : Address -> Html Msg
address address =
    let
        addTestId : CandidateAddress -> ( CandidateAddress, Int )
        addTestId ca =
            ( ca, address.test.id )
        notSureChoice = li [ style [ ( "text-indent", "-20px" ) ] ]
            [ input
                [ type' "button"
                , value " "
                , onClick (NoMatch address.test.id)
                ] []
            , span [ style [ ("font-weight", "bold" ) ] ]
                [ text " Pass ¯\\_(ツ)_/¯" ]
            ]
        testAddressHtml =
            h2
                [ class "heading-small" ]
                [ text (address.test.address)
                , br [] []
                , a
                    [ href (searchUrl address.test.address)
                    , target "blank"
                    , style [ ( "font-size", "70%" ) ]
                    ]
                    [ text "JFGI⧉" ]
                ]
    in
        li [ style [ ("clear", "both" ), ( "margin-left", "20px" ) ] ]
            [ testAddressHtml
            , embeddedMap (Debug.log ">>" address.test.address)
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
        [ width 300
        , height 400
        , style
            [ ( "border", "0" )
            , ( "float", "right" )
            , ( "margin-bottom", "20px" )
            ]
        , src ("https://www.google.com/maps/embed/v1/place?key=AIzaSyAJTbvZlhyNCaRDef08HD-OYC_CTPwk2Vc&q=" ++ search ++ ", United Kingdom")
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
        div [ style [ ("font-size", "80%") ]]
            [ error model.error
            , usersDropdown model.currentUserId model.users
            , addressSection
              -- , div [] [ text (toString model) ]
            ]
