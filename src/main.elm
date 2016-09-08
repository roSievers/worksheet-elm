import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value)
import Html.App as Html
import Html.Events exposing (..)
import Random



main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL


type alias Model =
  { exercises : List Exercise
  , newExercise : Exercise
  , currentUID : Int
  }

type alias Exercise =
  { title : String
  , text  : String
  , uid : Int
  }

blankExercise = (Exercise "" "" -1)


init : (Model, Cmd Msg)
init =
  (
    Model [
      Exercise "Regenbogenstraße" "In der Regenbogenstraße regnet es niemals." 1
    , Exercise "Hello World" "Generischer Blindtext um Platz zu verbrauchen." 2
    , Exercise "Fritz Kola" "Koffeinhaltige Limonade aus Hamburg." 3
    ] { blankExercise | uid = 10 } 20
    , Cmd.none
  )



-- UPDATE


type Msg
  = UpdateTitle String
  | UpdateText String
  | AddExcercise
  | DeleteExercise Int


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UpdateTitle title ->
      let
        oldExercise = model.newExercise
      in
        ({ model | newExercise = { oldExercise | title = title }}, Cmd.none)

    UpdateText text ->
      let
        oldExercise = model.newExercise
      in
        ({ model | newExercise = { oldExercise | text = text }}, Cmd.none)

    AddExcercise ->
      ({ model
        | newExercise = { blankExercise | uid = model.currentUID }
        , exercises = model.newExercise :: model.exercises
        , currentUID = model.currentUID + 1
      },Cmd.none)

    DeleteExercise uid ->
      ({ model
        | exercises = List.filter (\e -> e.uid /= uid) model.exercises
      }, Cmd.none)


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Html Msg
view model =
  div [ class "center" ]
    [ h1 [] [ text "Caption" ]
    , div []
      [ input [ type' "text", placeholder "Title", onInput UpdateTitle, value model.newExercise.title ] []
      , input [ type' "text", placeholder "Text", onInput UpdateText, value model.newExercise.text ] []
      , button [ onClick AddExcercise ] [ text "Add to List" ]
      ]
    , div [ class "catalog"] <| List.map renderExercise model.exercises
    ]


renderExercise : Exercise -> Html Msg
renderExercise exercise =
  div [ class "summary" ]
    [ div []
      [ h1 [] [ text (exercise.title) ]
      , span [ class "summary-hints" ]
        [ text ( toString exercise.uid )
        , button [ onClick (DeleteExercise exercise.uid)] [text "delete" ]
        ]
      , p [ class "summary-text" ] [ text exercise.text ]
      ]
    ]
