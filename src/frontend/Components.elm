module Components exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style, id, href)
import Html.App as Html
import Html.Events exposing (..)
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import ExerciseSheet exposing (ExerciseSheet)
import FontAwesome exposing (..)
import Icons as Fa


{-| TODO: This could also be called View a. Depending on the context either
might be better.
-}
type alias Decorator a =
    a -> Html Msg


layout model title content =
    div [ id "layout" ]
        [ a [ href "#menu", id "menuLink", class "menu-link" ]
            [ span [] [] ]
        , menu model
        , div [ id "main" ]
            [ header title
            , div [ class "content" ] [ content ]
            ]
        ]


{-| header : Model -> Html Msg
-}
menu model =
    div [ id "menu" ]
        [ div [ class "pure-menu" ]
            [ a [ class "pure-menu-heading", href "#" ] [ text "Worksheet" ]
            , ul [ class "pure-menu-list" ]
                [ li [ class "pure-menu-item" ]
                    [ a [ onClick (SetRoute Home), class "pure-menu-link" ] [ text " Home" ] ]
                , currentSheetButton model.sheet
                , li [ class "pure-menu-item" ]
                    [ a [ onClick (SetRoute Search), class "pure-menu-link" ] [ icon Fa.search, text " Search" ] ]
                ]
            ]
        ]


currentSheetButton : Maybe ExerciseSheet -> Html Msg
currentSheetButton sheet =
    case sheet of
        Nothing ->
            span [] []

        Just sheet' ->
            li [ class "pure-menu-item" ]
                [ a [ onClick (SetRoute Current), class "pure-menu-link" ] [ icon Fa.list, text " ", text sheet'.title ] ]


header content =
    div [ class "header" ] content


mainWithSidebar : List (Html msg) -> List (Html msg) -> Html msg
mainWithSidebar main sidebar =
    div [ class "pure-g" ]
        [ div [ class "pure-u-3-4" ]
            main
        , div [ class "pure-u-1-4 sidebar" ]
            [ div [] sidebar ]
        ]



{- <div class="pure-g">
       <div class="pure-u-1-3"><p>Thirds</p></div>
       <div class="pure-u-1-3"><p>Thirds</p></div>
       <div class="pure-u-1-3"><p>Thirds</p></div>
   </div>
-}


mainFullWidth : List (Html msg) -> Html msg
mainFullWidth main =
    div [ class "center" ]
        main


list : (a -> Html Msg) -> List a -> Html Msg
list itemRenderer items =
    div [ class "catalog" ] (List.map itemRenderer items)


dependentView : Decorator a -> Decorator a -> (a -> Bool) -> Decorator a
dependentView success failure property a =
    if property a then
        success a
    else
        failure a
