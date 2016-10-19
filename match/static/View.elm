module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed
import Http exposing (..)
import List exposing (..)
import InlineHover exposing (hover)
import Regex exposing (..)
import Animation
import Animation.Messenger
import String

import State exposing (..)
import Types exposing (..)
import User exposing (..)
import Address exposing (..)


postcodeRegex : Regex
postcodeRegex =
    regex "(GIR 0AA)|((([A-Z]\\d+)|(([A-Z]{2}\\d+)|(([A-Z][0-9][A-HJKSTUW])|([A-Z]{2}[0-9][ABEHMNPRVWXY]))))\\s?[0-9][A-Z]{2})"


searchUrl : String -> String
searchUrl search =
    url "https://www.google.co.uk/search"
        [ ( "q", search ) ]


mapUrl : String -> String
mapUrl search =
    url "https://www.google.com/maps/embed/v1/place"
        [ ( "key", "AIzaSyAJTbvZlhyNCaRDef08HD-OYC_CTPwk2Vc" )
        , ( "q", search )
        ]



-- Lists of style properties

styleCandidates : List (String, String)
styleCandidates =
        [ ( "margin-left", "60%" )
        , ( "margin-top", "1em" )
        , ( "width", "40%" )
        ]


styleCandidate : List (String, String)
styleCandidate =
        [ ( "margin-bottom", "1em" )
        , ( "padding", "3px" )
        , ( "border", "1px solid black" )
        , ( "background-color", "#DDD" )
        , ( "min-height", "5em" )
        ]


styleCandidateAddressHover : List (String, String)
styleCandidateAddressHover =
        [ ( "outline", "3px solid #F00" )
        ]

styleEmbeddedMap : List (String, String)
styleEmbeddedMap =
        [ ( "width", "98%" )
        , ( "height", "98%" )
        , ( "border", "0" )
        , ( "margin", "1%" )
        ]

styleFetchAddressButton : List (String, String)
styleFetchAddressButton =
        [ ( "font-size", "50px" )
        , ( "font-weight", "bold" )
        , ( "margin-top", "20px" )
        ]



-- HTML Generating Functions


viewExternalLink : String -> String -> Html Msg
viewExternalLink linkText linkHref =
    a
        [ href linkHref
        , target "blank"
        , style [ ( "font-size", "80%" ) ]
        ]
        [ Html.text linkText
        , sup [] [ Html.text "⧉" ]
        ]


viewEmbeddedMap : String -> Html Msg
viewEmbeddedMap search =
    iframe
        [ style styleEmbeddedMap
        , src (mapUrl (search ++ ", United Kingdom"))
        ]
        []



viewCandidate : Int -> ( CandidateAddress, TestAddressId ) -> (String, Html Msg)
viewCandidate index candidate =
    let
        candidateAddress =
            fst candidate

        testId =
            snd candidate
    in
        (candidateAddress.uprn
        ,hover
            styleCandidateAddressHover
            li
                [ style styleCandidate
                , onClick
                    (SelectCandidate ( candidateAddress.uprn, testId ))
                ]
                [ ul
                    []
                    [ li [] [ text candidateAddress.name ]
                    , li [] [ text candidateAddress.parentAddressName ]
                    , li [] [ text candidateAddress.streetName]
                    , li [] [ text candidateAddress.streetTown]
                    -- , viewExternalLink " map" (mapUrl candidateAddress.address)
                    ]
                ]
        )


viewAddress : Animation.Messenger.State Msg -> Address -> Html Msg
viewAddress animState address =
    let
        addTestId : CandidateAddress -> ( CandidateAddress, TestAddressId )
        addTestId ca =
            ( ca, address.test.id )

        testNameHtml =
            p [] [ text address.test.name ]

        testAddressHtml =
            div
                [ style
                    [ ( "position", "fixed" )
                    , ( "max-width", "42%" )
                    , ( "min-width", "42%" )
                    , ( "height", "300px" )
                    , ( "z-index", "2" )
                    , ( "background", "white" )
                    ]
                ]
                [ testNameHtml
                , h1
                    [ style
                        [ ( "margin", "0 0 .5em 0" )
                        , ( "border", "2px solid #BBB" )
                        , ( "padding", "3px" )
                        ]
                    ]
                    (List.concat
                        [ (map
                            (\line -> p [ style [("margin", "0")] ] [text line])
                            (String.split "," address.test.address))
                        ]
                    )
                , viewEmbeddedMap address.test.address
                ]
    in
        div
            (Animation.render animState
                ++ [ style [ ( "position", "relative" ) ] ]
            )
            [ testAddressHtml
            , div [ style styleCandidates ]
                [ h2 [ class "heading-medium" ] [ text "Click on the matching address below:" ]
                , Html.Keyed.ul []
                    (indexedMap viewCandidate (map addTestId address.candidates))
                , button
                    [ class "button"
                    , style [ ( "white-space", "nowrap" ) ]
                    , onClick (SelectCandidate ( "_unknown_", address.test.id ))
                    ]
                    [ Html.text "Pass ¯\\_(ツ)_/¯" ]
                ]
            ]


viewAddresses : Animation.Messenger.State Msg -> Int -> List Address -> Html Msg
viewAddresses animState numberRemaining addresses =
    div []
        ((viewProgressBar numberRemaining 5)
            :: (map (viewAddress animState) addresses)
        )


viewUserOption : UserId -> User -> Html Msg
viewUserOption currentUserId user =
    option
        [ value (user |> User.id |> toString)
        , selected (currentUserId == User.id user)
        ]
        [ user |> User.name |> Html.text ]


viewUserSelect : UserId -> List User -> Html Msg
viewUserSelect currentUserId users =
    select [ onInput UserChange ]
        ((option [] [ Html.text "Select a user" ])
            :: (map (viewUserOption currentUserId) users)
        )


viewUsersSection : UserId -> RemoteUsers -> Html Msg
viewUsersSection currentUserId users =
    div
        [ style [ ( "margin-bottom", "20px" ) ] ]
        [ case users of
            NotAsked ->
                p [] [ Html.text "Users not fetched " ]

            Loading ->
                p [] [ Html.text "Loading users" ]

            Success userList ->
                let
                    message =
                        if currentUserId == 0 then
                            "Please tell me who you are: "
                        else
                            "Current user: "
                in
                    div []
                        [ Html.text message
                        , viewUserSelect currentUserId userList
                        ]

            Failure error ->
                p []
                    [ Html.text
                        ("Error loading user data: " ++ (error |> toString))
                    ]
        ]


viewProgressBar : Int -> Int -> Html Msg
viewProgressBar remaining max =
    let
        percent : Float
        percent =
            100 * (toFloat (max-remaining+1)) / (toFloat max)
    in
        div
            [ style
                [ ( "height", "20px" )
                , ( "margin-bottom", "5px" )
                ]
            ]
            [ div
                [ style
                    [ ( "background-color", "#DDD" )
                    , ( "height", "20px" )
                    , ( "width", "100%")
                    ]
                ]
                [ "-" |> text ]
            , div
                [ style
                    [ ( "position", "relative" )
                    , ( "top", "-20px" )
                    , ( "background-color", "orange" )
                    , ( "color", "white" )
                    , ( "font-weight", "bold" )
                    , ( "font-size", "1em" )
                    , ( "height", "20px" )
                    , ( "width", (percent |> toString) ++ "%")
                    , ( "text-align", "center" )
                    ]
                ]
                [ (toString
                    (max + 1 - remaining)) ++ "/" ++ (toString max) |> Html.text
                ]
            ]


viewAddressSection : Animation.Messenger.State Msg -> UserId -> RemoteAddresses -> Html Msg
viewAddressSection animState currentUserId addresses =
    if currentUserId == 0 then
        p [] []
    else
        case addresses of
            Success listAddresses ->
                if listAddresses == [] then
                    div []
                        [ h1 [ class "heading-xlarge" ] [ text "All done!" ]
                        , button
                            [ onClick FetchAddresses
                            , style styleFetchAddressButton
                            ]
                            [ Html.text "Give me more!" ]
                        ]
                else
                    viewAddresses
                        animState
                        (length listAddresses)
                        (take 1 listAddresses)

            Loading ->
                p [] [ Html.text "Loading test addresses" ]

            Failure err ->
                p [] [ Html.text ("Failed loading addresses: " ++ (toString err)) ]

            NotAsked ->
                p [] [ Html.text "Loading test addresses" ]


view : Model -> Html Msg
view model =
    div
        [ style [ ( "font-size", "90%" ) ] ]
        [ viewUsersSection model.currentUserId model.users
        , viewAddressSection
            model.animationStyle model.currentUserId model.addresses
        ]
