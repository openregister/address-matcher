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
import Css

import State exposing (..)
import Types exposing (..)
import User exposing (..)
import Address exposing (..)


postcodeRegex : Regex
postcodeRegex =
    regex "(GIR 0AA)|((([A-Z]\\d+)|(([A-Z]{2}\\d+)|(([A-Z][0-9][A-HJKSTUW])|([A-Z]{2}[0-9][ABEHMNPRVWXY]))))\\s?[0-9][A-Z]{2})"


extractPostcode : String -> String
extractPostcode text =
    let
        match =
            find (AtMost 1) postcodeRegex text
                |> head
    in
        case match of
            Nothing ->
                text

            Just m ->
                m.match


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


styleCandidate : Int -> List (String, String)
styleCandidate index =
    let
        always =
                [ Css.marginLeft (Css.em 1)
                , Css.paddingLeft (Css.em 0.2)
                ]
    in
        if index % 2 == 0 then
            Css.asPairs (Css.backgroundColor (Css.hex "EEE" ) :: always)
        else
            Css.asPairs always


styleCandidateAddressHover : List (String, String)
styleCandidateAddressHover =
    Css.asPairs
        [ Css.outline3 (Css.px 3) Css.solid (Css.hex "F00")
        , Css.borderRadius (Css.px 10)
        ]

styleEmbeddedMap : List (String, String)
styleEmbeddedMap =
    Css.asPairs
        [ Css.border (Css.px 0)
        , Css.marginBottom (Css.px 20)
        ]

styleFetchAddressButton : List (String, String)
styleFetchAddressButton =
    Css.asPairs
        [ Css.fontSize (Css.px 50)
        , Css.fontWeight Css.bold
        , Css.marginTop (Css.px 20)
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
        [ width 300
        , height 400
        , class "column-one-third"
        , style styleEmbeddedMap
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
                [ style (styleCandidate index)
                , onClick
                    (SelectCandidate (Just ( candidateAddress.uprn, testId )))
                ]
                [ Html.text ("➞ " ++ candidateAddress.address)
                , text " "
                , small []
                [ viewExternalLink " map" (mapUrl candidateAddress.address) ]
                ]
        )


viewAddress : Animation.Messenger.State Msg -> Address -> Html Msg
viewAddress animState address =
    let
        addTestId : CandidateAddress -> ( CandidateAddress, TestAddressId )
        addTestId ca =
            ( ca, address.test.id )

        notSureChoice =
            hover
                styleCandidateAddressHover
                li
                    [ style (styleCandidate -1)
                    , onClick (SelectCandidate Nothing)
                    ]
                    [ span
                        [ style
                            [ ( "font-weight", "bold" ) ]
                        ]
                        [ Html.text "Pass ¯\\_(ツ)_/¯" ]
                    ]

        testAddressHtml =
            h1
                [ class "heading-medium" ]
                [ Html.text (address.test.address)
                , span [] [ Html.text " - " ]
                , viewExternalLink "Search" (searchUrl address.test.address)
                ]
    in
        div
            (Animation.render animState
                ++ [ style [ ( "position", "relative" ) ] ]
            )
            [ testAddressHtml
            , div
                [ class "grid-row" ]
                [ Html.Keyed.ul [ class "column-two-thirds" ]
                    (("pass", notSureChoice)
                        :: (indexedMap viewCandidate (map addTestId address.candidates))
                    )
                , viewEmbeddedMap (extractPostcode address.test.address)
                ]
            ]


viewAddresses : Animation.Messenger.State Msg -> Int -> List Address -> Html Msg
viewAddresses animState numberDone addresses =
    div []
        (viewProgressBar (20 * (5 - numberDone))
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
                            "Please tell me who you are:"
                        else
                            "Current user:"
                in
                    div []
                        [ p [] [ Html.text message ]
                        , viewUserSelect currentUserId userList
                        ]

            Failure error ->
                p []
                    [ Html.text
                        ("Error loading user data: " ++ (error |> toString))
                    ]
        ]


viewProgressBar : Int -> Html Msg
viewProgressBar percent =
    let
        pc =
            (percent |> toString) ++ "%"
    in
        div
            [ style
                [ ( "background-color"
                  , if percent == 0 then
                        "white"
                    else
                        "green"
                  )
                , ( "color"
                  , if percent == 0 then
                        "black"
                    else
                        "white"
                  )
                , ( "font-weight", "bold" )
                , ( "font-size", "2em" )
                , ( "width"
                  , if percent == 0 then
                        "100px"
                    else
                        pc
                  )
                , ( "text-align", "center" )
                ]
            ]
            [ pc |> Html.text ]


viewAddressSection : Animation.Messenger.State Msg -> UserId -> RemoteAddresses -> Html Msg
viewAddressSection animState currentUserId addresses =
    if currentUserId == 0 then
        p [] []
    else
        case addresses of
            Success listAddresses ->
                if listAddresses == [] then
                    div []
                        [ viewProgressBar 100
                        , p
                            [ style
                                [ ( "font-size", "20px" ) ]
                            ]
                            [ Html.text "Your score is 244" ]
                        , p
                            [ style
                                [ ( "font-size", "30px" )
                                , ( "color", "gold" )
                                ]
                            ]
                            [ Html.text "🏆 You're in first place! 🏆" ]
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
                p [] [ Html.text "Loading addresses" ]

            _ ->
                p [] [ Html.text "No addresses" ]


view : Model -> Html Msg
view model =
    div
        [ style [ ( "font-size", "90%" ) ] ]
        [ viewUsersSection model.currentUserId model.users
        , viewAddressSection
            model.animationStyle model.currentUserId model.addresses
        ]
