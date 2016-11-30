module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Keyed
import Http exposing (encodeUri)
import List exposing (..)
import InlineHover exposing (hover)
import Regex exposing (..)
import Animation
import String
import State exposing (..)
import Types exposing (..)
import User exposing (..)
import Address exposing (..)
import DataSetInfo exposing (..)


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
    "https://www.google.co.uk/search?q=" ++ (encodeUri search)


mapUrl : String -> String
mapUrl search =
    "https://www.google.com/maps/embed/v1/place?key=AIzaSyAJTbvZlhyNCaRDef08HD-OYC_CTPwk2Vc&q="
        ++ (encodeUri search)


generator : String -> Attribute msg
generator name =
    attribute "data-elm-generator" name


-- lower case all text except first letter of each word
capitaliseWords : String -> String
capitaliseWords =
        String.toLower
            >> replace All (regex "\\b[a-z]") (\{match} -> String.toUpper match)



-- Lists of style properties


styleCandidate : List ( String, String )
styleCandidate =
    [ ( "display", "inline-block" )
    , ( "width", "30%" )
    , ( "margin", ".1em .4em 0 0" )
    , ( "padding", "3px" )
    , ( "border-radius", "10px" )
    , ( "background-color", "#DDD" )
    , ( "height", "7em" )
    , ( "overflow-y", "auto" )
    ]


styleCandidateHover : List ( String, String )
styleCandidateHover =
    [ ( "outline", "3px solid brown" ) ]


styleEmbeddedMap : List ( String, String )
styleEmbeddedMap =
    [ ( "width", "98%" )
    , ( "height", "15em" )
    , ( "border", "0" )
    , ( "margin", "1em 0 0 0" )
    ]



-- HTML Generating Functions


viewTopUser : UserId -> User -> Html Msg
viewTopUser currentUserId user =
    li
        []
        [ if (User.id user) == currentUserId then
            strong [] [ text ("You: " ++ (toString (User.score user))) ]
          else
            text ((User.name user) ++ ": " ++ (toString (User.score user)))
        ]


viewTopUsers : Model -> Html Msg
viewTopUsers model =
    case model.users of
        Success users ->
            let
                nonZeroSortedUsers =
                    users
                        |> filter (\u -> (score u) /= 0)
                        |> sortBy score
                        |> reverse
            in
                if nonZeroSortedUsers /= [] then
                    div
                        [ generator "viewTopUsers"
                        , class "user-stats"
                        ]
                        [ h2 [ class "heading-small" ] [ text "Top users" ]
                        , div
                            [ class "user-stats-inner" ]
                            [ ul
                                []
                                (List.map
                                  (viewTopUser model.currentUserId)
                                  nonZeroSortedUsers
                                )
                            ]
                        ]
                else
                    div [] []
        _ ->
            div [] []


viewEmbeddedMap : String -> Html Msg
viewEmbeddedMap search =
    iframe
        [ generator "viewEmbeddedMap"
        , style styleEmbeddedMap
        , src (mapUrl (search ++ ", United Kingdom"))
        ]
        []


-- converts to array for pretty printing
viewCandidateText : Candidate -> List (Html Msg)
viewCandidateText c =
    let
        lengthThreshold = 5
        a = c.name |> capitaliseWords
        p = c.parentAddressName |> capitaliseWords
        s = c.streetName |> capitaliseWords
        t = c.streetTown |> capitaliseWords
        lf = br [] []
        comma = span [] [text ", "]
    in
        if String.length a == 0 then
            if String.length p == 0 then
                [ text s, lf, text t ]
            else
                if String.length p < lengthThreshold then
                    [ text p, comma, text s, lf, text t ]
                else
                    [ text p, lf, text s, lf, text t ]
        else
            if String.length a < lengthThreshold then
                if String.length p == 0 then
                    [ text a, comma, text s, lf, text t ]
                else
                    if String.length p < lengthThreshold then
                        [ text a, lf, text p, comma, text s, lf, text t ]
                    else
                        [ text a, comma, text p, lf, text s, lf, text t ]
            else
                if String.length p == 0 then
                    [ text a, lf, text s, lf, text t ]
                else
                    if String.length p < lengthThreshold then
                        [ text a, lf, text p, comma, text s, lf, text t ]
                    else
                        [ text a, lf, text p, lf, text s, lf, text t ]


viewCandidate : ( Candidate, TestId ) -> Html Msg
viewCandidate candidateTestId =
    let
        candidate =
            Tuple.first candidateTestId

        testId =
            Tuple.second candidateTestId
    in
        hover
            styleCandidateHover
            li
            [ generator "viewCandidate"
            , style styleCandidate
            , onClick
                (SelectCandidate ( candidate.uprn, testId ))
            ]
            (viewCandidateText candidate)


viewPassButton : TestId -> Html Msg
viewPassButton testId =
    button
        [ class "button"
        , style
            [ ( "white-space", "nowrap" )
            , ( "line-height", ".6" )
            ]
        , onClick (SelectCandidate ( "_unknown_", testId ))
        ]
        [ text "Pass" ]


viewTestLine : String -> Html Msg
viewTestLine line =
    p [ style [ ( "margin", "0" ) ] ] [ text line ]


viewTest : Test -> Html Msg
viewTest test =
    let
        testNameHtml =
            p
                [ style
                    [ ( "font-weight", "bold" )
                    , ( "margin-bottom", "0" )
                    ]
                ]
                [ text test.name ]
    in
        div
            [ generator "viewTest"
            , class "test-address" ]
            [ testNameHtml
            , h2
                []
                (List.concat
                    [ (List.map
                        viewTestLine
                        (String.split "," test.address)
                      )
                    ]
                )
            , viewEmbeddedMap
                (test.name ++ ", " ++ (extractPostcode test.address))
            ]


viewCandidates : TestId -> List Candidate -> Html Msg
viewCandidates testId candidates =
    Html.Keyed.node "div"
        [ generator "viewCandidates"
        , style
            [ ( "float", "right" )
            , ( "width", "69%" )
            ]
        ]
        [ ( (toString testId) ++ "h2"
          , h2
                [ class "heading-small" ]
                [ text "Select the matching address below, or "
                , viewPassButton testId
                ]
          )
        , ( (toString testId) ++ "ul"
          , ul
                []
                (List.map
                    viewCandidate
                    (List.map (\c -> (c, testId)) candidates)
                )
          )
        ]

viewCard : Model -> Address -> Html Msg
viewCard model address =
    div
        (Animation.render model.animationStyle
            ++ [ generator "viewCard"
               , style [ ( "position", "relative" ) ]
               ]
        )
        [ div
            [ class "grid-row" ]
            [ viewTest address.test
            , viewCandidates address.test.id address.candidates
            ]
        ]


viewMatcher : Model -> Int -> Address -> Html Msg
viewMatcher model numberRemaining address =
    div
        [ generator "viewMatcher"
        ]
        [ viewProgressBar numberRemaining 5
        , viewCard model address
        ]


viewUserOption : UserId -> User -> Html Msg
viewUserOption currentUserId user =
    option
        [ value (user |> User.id |> toString)
        , selected (currentUserId == User.id user)
        ]
        [ user |> User.name |> text ]


viewUserSelect : UserId -> List User -> Html Msg
viewUserSelect currentUserId users =
    select
        [ generator "viewUserSelect"
        , onInput UserChange
        ]
        ((option [] [ text "Select a user" ]) ::
            (List.map
                (viewUserOption currentUserId)
                (users |> sortBy User.name)
            )
        )


viewUsersSection : Model -> Html Msg
viewUsersSection model =
    div
        [ generator "viewUsersSection"
        , style
              [ ( "margin", "20px 0 20px 0" )
              , ( "font-size", "1.3em" )
              ]
        ]
        [ case model.users of
            NotAsked ->
                p [] [ text "Users not fetched " ]

            Loading ->
                p [] [ text "Loading users" ]

            Success userList ->
                let
                    message =
                        if model.currentUserId == 0 then
                            "Please tell me who you are: "
                        else
                            "Current user: "
                in
                    div [ style [ ( "text-align", "center" ) ] ]
                        [ text message
                        , viewUserSelect model.currentUserId userList
                        ]

            Failure error ->
                p []
                    [ text
                        ("Error loading user data: " ++ (error |> toString))
                    ]
        ]


viewProgressBar : Int -> Int -> Html Msg
viewProgressBar remaining max =
    let
        percent : Float
        percent =
            100 * (toFloat (max - remaining + 1)) / (toFloat max)
    in
        div
            [ generator "viewProgressBar"
            , style
                [ ( "height", "20px" )
                , ( "margin-bottom", "5px" )
                ]
            ]
            [ div
                [ style
                    [ ( "background-color", "#DDD" )
                    , ( "height", "20px" )
                    , ( "width", "100%" )
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
                    , ( "width", (percent |> toString) ++ "%" )
                    , ( "text-align", "center" )
                    ]
                ]
                [ (toString
                    (max + 1 - remaining)
                  )
                    ++ "/"
                    ++ (toString max)
                    |> text
                ]
            ]


viewFinishedSection : Model -> Html Msg
viewFinishedSection model =
    div [ generator "viewFinishedSection" ]
        [ h2 [ class "heading-large" ] [ text "Well done!" ]
        , button
              [ onClick FetchAddresses
              , class "button"
              ]
              [ text "Give me more!" ]
        , p [ style [ ( "padding-top", "1em" ) ] ]
            [ a
                [ href "/match/scores/" ]
                [ text "See all stats" ]
            ]
        ]


viewMatcherSection : Model -> Html Msg
viewMatcherSection model =
    div
        [ generator "viewMatcherSection" ]
        [ if model.currentUserId == 0 then
            p [] []
          else
            case model.addresses of
                Success listAddresses ->
                    case head listAddresses of
                        Nothing ->
                            viewFinishedSection model

                        Just address ->
                            viewMatcher
                                model
                                (length listAddresses)
                                address

                Loading ->
                    p [] [ text "Loading test addresses" ]

                Failure err ->
                    p [] [ text ("Failed loading addresses: " ++ (toString err)) ]

                NotAsked ->
                    p [] [ text "Loading test addresses" ]
        ]


viewInfoSection : Model -> Html Msg
viewInfoSection model =
    h1
        [ generator "viewInfoSection"
        , class "heading-small"
        ]
        [ case model.dataSetInfo of
            NotAsked ->
                text "Fetching"

            Loading ->
                text "Loading infos"

            Success infoDict ->
                case model.addresses of
                    Success _ ->
                        DataSetInfo.get "title" infoDict
                            |> Maybe.withDefault "No title"
                            |> text
                    _ ->
                        text ""

            Failure error ->
                text ("Error loading dataset title" ++ (error |> toString))
        ]

viewScore : Model -> Html Msg
viewScore model =
    if model.lastMatchScore > 1 then
        div
            [ generator "viewScore"
            , class "score"
            ]
            [ text
                ("Good Guess! You earned "
                    ++ (toString model.lastMatchScore)
                    ++ " points"
                )
            , div
                [ title "You score more points when your guesses match that of other players"
                , class "help-pill"
                ]
                [ text "?" ]
            ]
    else
        div [ style [ ( "display", "none" ) ] ] []


view : Model -> Html Msg
view model =
    div
        [ generator "view"
        , style [ ( "font-size", "90%" ) ]
        ]
        [ viewUsersSection model
        , viewInfoSection model
        , viewMatcherSection model
        , viewTopUsers model
        , viewScore model
        ]
