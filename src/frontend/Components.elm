module Components exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style, id, href)
import Html.App as Html
import Html.Events exposing (..)
import List.Extra
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import Sheet exposing (Sheet)
import FontAwesome exposing (..)
import Icons as Fa
import Model exposing (Model)


{-| TODO: This could also be called View a. Depending on the context either
might be better.
-}
type alias Decorator a =
    a -> Html Msg


type alias IndexDecorator a =
    Int -> a -> Html Msg


layout : Model -> List (Html Msg) -> Html Msg -> Html Msg
layout model title content =
    div
        [ id "layout"
        , if model.responsiveMenuActive then
            class "active"
          else
            class ""
        ]
        [ a
            [ href "#menu"
            , id "menuLink"
            , if model.responsiveMenuActive then
                class "menu-link active"
              else
                class "menu-link"
            , onClick ToggleResponsiveMenu
            ]
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
    div
        [ id "menu"
        , if model.responsiveMenuActive then
            class "active"
          else
            class ""
        ]
        [ div [ class "pure-menu" ]
            [ span [ class "pure-menu-heading" ] [ text "Worksheet" ]
            , ul [ class "pure-menu-list" ]
                ([ Home, Current, Search ]
                    |> List.map (routeButton model)
                    |> List.filterMap identity
                )
            ]
        ]


routeButton : Model -> Route -> Maybe (Html Msg)
routeButton model route =
    Maybe.map
        (\caption ->
            li
                [ if model.route == route then
                    class "pure-menu-item pure-menu-selected"
                  else
                    class "pure-menu-item"
                ]
                [ a
                    [ onClick (SetRoute route)
                    , class "pure-menu-link"
                    , href "#"
                    ]
                    caption
                ]
        )
        (routeCaption model route)


routeCaption : Model -> Route -> Maybe (List (Html Msg))
routeCaption model route =
    case route of
        Home ->
            Just [ text " Home" ]

        Current ->
            Maybe.map
                (\sheet ->
                    [ icon Fa.list, text " ", text sheet.title ]
                )
                model.sheet

        Search ->
            Just [ icon Fa.search, text " Search" ]


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


mainFullWidth : List (Html msg) -> Html msg
mainFullWidth main =
    div [ class "center" ]
        main


list : IndexDecorator a -> List a -> Html Msg
list itemRenderer items =
    div [ class "catalog" ] (List.indexedMap itemRenderer items)


listIntersperse : IndexDecorator () -> IndexDecorator a -> List a -> Html Msg
listIntersperse intersperseView itemView items =
    div [ class "catalog" ]
        (List.Extra.interweave
            (List.indexedMap intersperseView (List.repeat (1 + List.length items) ()))
            (List.indexedMap itemView items)
        )


dependentView : Decorator a -> Decorator a -> (a -> Bool) -> Decorator a
dependentView success failure property a =
    if property a then
        success a
    else
        failure a
