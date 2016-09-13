module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style)
import Html.App as Html
import Html.Events exposing (..)
import Random
import Http
import Json.Decode as Json exposing ((:=))
import Task
import Debug exposing (crash)
import Components exposing (..)
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)

main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias WithUID a =
    { a | uid : Int }


type alias Model =
    { route : Route
    , exercises : List Exercise
    , newExercise : Exercise
    , currentUID : Int
    }




blankExercise =
    (Exercise "" "" -1 False)


buildExercise title text uid =
    { blankExercise | title = title, text = text, uid = uid }



-- Decoding Exercises


decodeExercise =
    Json.object3 buildExercise
        ("title" := Json.string)
        ("text" := Json.string)
        ("uid" := Json.int)


decodeExerciseList : Json.Decoder (List Exercise)
decodeExerciseList =
    ("exercises" := Json.list decodeExercise)


requestExerciseList : Cmd Msg
requestExerciseList =
    Http.get decodeExerciseList ("http://localhost:8000/data/search.json")
        |> Task.perform (\x -> LoadingFail x) (\list -> LoadingDone list)


init : ( Model, Cmd Msg )
init =
    ( Model
        Home
        []
        { blankExercise | uid = 1000 }
        1001
    , requestExerciseList
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateTitle title ->
            let
                oldExercise =
                    model.newExercise
            in
                ( { model | newExercise = { oldExercise | title = title } }, Cmd.none )

        UpdateText text ->
            let
                oldExercise =
                    model.newExercise
            in
                ( { model | newExercise = { oldExercise | text = text } }, Cmd.none )

        CreateExercise ->
            ( { model
                | newExercise = { blankExercise | uid = model.currentUID }
                , exercises = model.newExercise :: model.exercises
                , currentUID = model.currentUID + 1
              }
            , Cmd.none
            )

        DeleteExercise uid ->
            ( { model
                | exercises = List.filter (\e -> e.uid /= uid) model.exercises
              }
            , Cmd.none
            )

        AddExercise uid ->
            ( { model
                | exercises = mapOnUID uid (\e -> { e | inActiveContainer = True }) model.exercises
              }
            , Cmd.none
            )

        RemoveExercise uid ->
            ( { model
                | exercises = mapOnUID uid (\e -> { e | inActiveContainer = False }) model.exercises
              }
            , Cmd.none
            )

        SetRoute route ->
            ( { model
                | route = route
              }
            , Cmd.none
            )

        LoadingFail err ->
            crash "LoadingFail"

        LoadingDone new ->
            ( { model
                | exercises = List.append model.exercises new
              }
            , Cmd.none
            )


mapOnUID : Int -> (WithUID a -> WithUID a) -> List (WithUID a) -> List (WithUID a)
mapOnUID uid f list =
    let
        saveF a =
            if a.uid == uid then
                f a
            else
                a
    in
        List.map saveF list



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ renderHeader model
        , div [ class "center" ]
            (case model.route of
                Search ->
                    [ renderMainPannel model
                    , renderSidebar model
                    ]

                Sheet ->
                    [ renderSheetPanel model
                    , renderSidebar model
                    ]

                Home ->
                    [ h1 [] [ text "Welcome" ]
                    , p [] [ text "\"Choose\" a worksheet to edit:" ]
                    , button [ onClick (SetRoute Sheet) ] [ text "The only Sheet." ]
                    ]
            )
        ]


renderSheetPanel : Model -> Html Msg
renderSheetPanel model =
    div [ class "main-pannel" ]
        [ h1 [] [ text "Current Selection" ]
        , inContainer model
            |> List.map renderExercise
            |> div [ class "catalog" ]
        ]


inContainer : Model -> List Exercise
inContainer model =
    model.exercises
        |> List.filter (\e -> e.inActiveContainer)


renderMainPannel : Model -> Html Msg
renderMainPannel model =
    div [ class "main-pannel" ]
        [ h1 [] [ text "All Exercises" ]
        , div []
            [ input [ type' "text", placeholder "Title", onInput UpdateTitle, value model.newExercise.title ] []
            , input [ type' "text", placeholder "Text", onInput UpdateText, value model.newExercise.text ] []
            , button [ onClick CreateExercise ] [ text "Add to List" ]
            ]
        , div [ class "catalog" ] <| List.map renderExercise model.exercises
        ]


renderSidebar : Model -> Html Msg
renderSidebar model =
    div [ class "sidebar" ]
        [ h1 []
            [ h2 [] [ text "sidebar" ]
            , p []
                [ text "Count: "
                , inContainer model
                    |> List.length
                    |> toString
                    |> text
                ]
            ]
        ]


renderExercise : Exercise -> Html Msg
renderExercise exercise =
    div [ class "summary" ]
        [ div []
            [ h1 [] [ text (exercise.title) ]
            , span [ class "summary-hints" ]
                [ if exercise.inActiveContainer then
                    button [ onClick (RemoveExercise exercise.uid) ] [ text "Remove Exercise" ]
                  else
                    button [ onClick (AddExercise exercise.uid) ] [ text "Add Exercise" ]
                , button [ onClick (DeleteExercise exercise.uid) ] [ text "delete" ]
                ]
            , p [ class "summary-text" ] [ text exercise.text ]
            ]
        ]
