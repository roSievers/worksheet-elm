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
  }

type alias Exercise =
  { title : String
  , text  : String
  }

blankExercise = (Exercise "" "")


init : (Model, Cmd Msg)
init =
  (
    Model [
      Exercise "Regenbogenstraße" "In der Regenbogenstraße regnet es niemals."
    , Exercise "Hello World" "Generischer Blindtext um Platz zu verbrauchen."
    , Exercise "Fritz Kola" "Koffeinhaltige Limonade aus Hamburg."
    ] blankExercise
    , Cmd.none
  )



-- UPDATE


type Msg
  = UpdateTitle String
  | UpdateText String
  | AddExcercise


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
      ({ model | newExercise = blankExercise, exercises = model.newExercise :: model.exercises}, Cmd.none)


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
        [ button [] [ text "delete" ]
        ]
      , p [ class "summary-text" ] [ text exercise.text ]
      ]
    ]
