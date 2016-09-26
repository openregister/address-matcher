module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import List exposing (..)
import InlineHover exposing (hover)
import State exposing (..)
import Types exposing (..)
import User exposing (..)


searchUrl : String -> String
searchUrl search =
    url "https://www.google.co.uk/search"
        [ ( "q", search ) ]


mapUrl : String -> String
mapUrl search =
    url "https://www.google.com/maps/embed/v1/place"
        [ ( "key", "AIzaSyAJTbvZlhyNCaRDef08HD-OYC_CTPwk2Vc" ), ( "q", search ) ]


candidate : ( CandidateAddress, TestAddressId ) -> Html Msg
candidate candidate =
    let
        candidateAddress =
            fst candidate

        testId =
            snd candidate
    in
        hover
            [ ( "border", "3px solid red" )
            , ( "border-radius", "10px" )
            ]
            li
            [ style
                [ ( "border", "3px solid white" )
                , ( "padding-left", ".2em" )
                ]
            , onClick (SelectCandidate ( candidateAddress.uprn, testId ))
            ]
            [ text (" " ++ candidateAddress.address)
            , text " "
            , small []
                [ a
                    [ href (mapUrl candidateAddress.address)
                    , target "_blank"
                    ]
                    [ text "map⧉" ]
                ]
            ]


address : Address -> Html Msg
address address =
    let
        addTestId : CandidateAddress -> ( CandidateAddress, TestAddressId )
        addTestId ca =
            ( ca, address.test.id )

        notSureChoice =
            hover
                [ ( "border", "3px solid red" )
                , ( "border-radius", "10px" )
                ]
                li
                [ style
                    [ ( "border", "3px solid white" )
                    , ( "padding-left", ".2em" )
                    ]
                , onClick (NoMatch address.test.id)
                ]
                [ span
                    [ style
                        [ ( "font-weight", "bold" ) ]
                    ]
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
                    ]
                    [ text "JFGI⧉" ]
                ]
    in
        li
            [ style [ ( "clear", "both" ) ] ]
            [ testAddressHtml
            , embeddedMap address.test.address
            , ul []
                (notSureChoice
                    :: (map candidate (map addTestId address.candidates))
                )
            ]


addresses : List Address -> Html Msg
addresses addresses =
    ul [] (map address addresses)


userOption : UserId -> User -> Html Msg
userOption currentUserId user =
    option
        [ value (user |> User.id |> toString)
        , selected (currentUserId == User.id user)
        ]
        [ user |> User.name |> text ]


userSelect : UserId -> List User -> Html Msg
userSelect currentUserId users =
    select [ onInput UserChange ]
        ((option [] [ text "Select a user" ])
            :: (map (userOption currentUserId) users)
        )


usersSection : UserId -> RemoteUsers -> Html Msg
usersSection currentUserId users =
    case users of
        NotAsked ->
            p [] [ text "Users not fetched " ]

        Loading ->
            p [] [ text "Loading users" ]

        Success userList ->
            let
                message =
                    if currentUserId == 0 then
                        "Please tell me who you are:"
                    else
                        "Current user:"
            in
                div []
                    [ p [] [ text message ]
                    , userSelect currentUserId userList
                    ]

        Failure error ->
            p [] [ text ("Error loading user data: " ++ (error |> toString)) ]


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
        , src (mapUrl (search ++ ", United Kingdom"))
        ]
        []


view : Model -> Html Msg
view model =
    let
        addressSection : Html Msg
        addressSection =
            if model.currentUserId == 0 then
                p [] []
            else
                case model.addresses of
                    Success listAddresses ->
                        if listAddresses == [] then
                            p []
                                [ button
                                    [ onClick FetchAddresses ]
                                    [ text "More!" ]
                                ]
                        else
                            addresses (take 1 listAddresses)

                    Loading ->
                        p [] [ text "Loading addresses" ]

                    _ ->
                        p [] [ text "No addresses" ]
    in
        div
            [ style [ ( "font-size", "90%" ) ] ]
            [ usersSection model.currentUserId model.users
            , addressSection
              -- , div [] [ text (toString model) ]
            ]
