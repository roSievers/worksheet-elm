module Main exposing (..)

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
import ExerciseSheet exposing (ExerciseSheet)


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
    , sheet : ExerciseSheet
    , newExercise : Exercise
    , currentUID : Int
    }


init : ( Model, Cmd Msg )
init =
    ( Model
        Home
        []
        (ExerciseSheet.fromList [])
        { blankExercise | uid = 1000 }
        1001
    , Cmd.batch
        [ requestExerciseList SearchResultsArrived "./data/search.json"
        , requestExerciseList SheetArrived "./data/sheet.json"
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

        DeleteExercise uid ->
            ( { model
                | exercises = List.filter (\e -> e.uid /= uid) model.exercises
              }
            , Cmd.none
            )

        AddExercise exercise ->
            ( { model
                | sheet = ExerciseSheet.insert exercise model.sheet
              }
            , Cmd.none
            )

        RemoveExercise uid ->
            ( { model
                | sheet = ExerciseSheet.remove uid model.sheet
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
                | sheet = ExerciseSheet.fromList new
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
        , Components.exerciseList model.sheet (model.sheet.list)
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
        , p []
            [ text "Count: "
            , model.sheet.list
                |> List.length
                |> toString
                |> text
            ]
        ]
