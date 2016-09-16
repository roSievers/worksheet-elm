module Main exposing (..)

import Task
import Cmd.Extra
import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style)
import Html.App as Html
import Html.Events exposing (..)
import Debug exposing (crash)
import Components
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import Requests exposing (..)
import ExerciseSheet exposing (ExerciseSheet, LazySheet)


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
    , sheet : Maybe ExerciseSheet
    , sheets : Maybe (List LazySheet)
    , newExercise : Exercise
    , currentUID : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { route = Home
      , exercises = []
      , sheet = Nothing
      , sheets = Nothing
      , newExercise = { blankExercise | uid = 1000 }
      , currentUID = 1001
      }
    , Cmd.batch
        [ requestExerciseList SearchResultsArrived "./data/search.json"
        , Task.perform LoadingFail SheetListArrived ExerciseSheet.loadSheetList
        ]
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

        SetRoute route ->
            ( { model
                | route = route
              }
            , Cmd.none
            )

        LoadingFail err ->
            crash "LoadingFail"

        SearchResultsArrived new ->
            ( { model
                | exercises = List.append model.exercises new
              }
            , Cmd.none
            )

        SheetArrived new ->
            ( { model
                | sheet = Just new
              }
            , Cmd.none
            )

        ExerciseMessage msg' ->
            updateExercise msg' model

        SheetListArrived sheets ->
            ( { model
                | sheets = Just sheets
              }
            , Cmd.none
            )

        SetSheet lsheet ->
            ( model, Task.perform LoadingFail SheetArrived <| ExerciseSheet.load lsheet )

        CloseSheet ->
            ( { model
                | sheet = Nothing
              }
            , if model.route == Sheet then
                Cmd.Extra.message (SetRoute Home)
              else
                Cmd.none
            )


updateExercise : ExerciseMsg -> Model -> ( Model, Cmd Msg )
updateExercise msg model =
    case msg of
        AddExercise exercise ->
            ( { model
                | sheet = Maybe.map (ExerciseSheet.insert exercise) model.sheet
              }
            , Cmd.none
            )

        RemoveExercise uid ->
            ( { model
                | sheet = Maybe.map (ExerciseSheet.remove uid) model.sheet
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
        [ Components.header model
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
                    [ renderHomePanel model
                    ]
            )
        ]


renderHomePanel : Model -> Html Msg
renderHomePanel model =
    case model.sheets of
        Nothing ->
            div []
                [ h1 [] [ text "Welcome" ]
                , p [] [ text "No Worksheets known." ]
                ]

        Just sheets ->
            div [] <|
                List.append
                    [ h1 [] [ text "Welcome" ]
                    , p [] [ text "Choose an execise sheet to work on" ]
                    ]
                    (List.map renderLoadSheetButton sheets)


renderLoadSheetButton : LazySheet -> Html Msg
renderLoadSheetButton lsheet =
    button [ onClick (SetSheet lsheet) ] [ text lsheet.title ]


renderSheetPanel : Model -> Html Msg
renderSheetPanel model =
    case model.sheet of
        Nothing ->
            div [ class "main-pannel" ]
                [ h1 [] [ text "No Sheet selected." ]
                , button [ onClick (SetRoute Home) ] [ text "Return to landing Page." ]
                ]

        Just sheet' ->
            div [ class "main-pannel" ]
                [ h1 []
                    [ text sheet'.title
                    , span [ class "summary-hints" ]
                        [ button [ onClick CloseSheet ] [ text "Close" ]
                        ]
                    ]
                , Components.exerciseList model.sheet (sheet'.list)
                ]


renderMainPannel : Model -> Html Msg
renderMainPannel model =
    div [ class "main-pannel" ]
        [ h1 [] [ text "All Exercises" ]
        , div []
            [ input [ type' "text", placeholder "Title", onInput UpdateTitle, value model.newExercise.title ] []
            , input [ type' "text", placeholder "Text", onInput UpdateText, value model.newExercise.text ] []
            , button [ onClick CreateExercise ] [ text "Add to List" ]
            ]
        , Components.exerciseList model.sheet model.exercises
        ]


renderSidebar : Model -> Html Msg
renderSidebar model =
    div [ class "Sidebar" ]
        [ h1 [] [ text "sidebar" ]
        , case model.sheet of
            Nothing ->
                p [] []

            Just sheet' ->
                p []
                    [ text "Count: "
                    , sheet'
                        |> ExerciseSheet.length
                        |> toString
                        |> text
                    ]
        ]
