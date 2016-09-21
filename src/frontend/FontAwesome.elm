module FontAwesome
    exposing
        ( Icon
        , base
        , icon
        , Size(..)
        , small
        , large
        , double
        , tripple
        , quadruple
        , quintuple
        , fixWidth
        , withBorder
        , pullLeft
        , pullRight
        , spinning
        , pulsing
        , rotate90
        , rotate180
        , rotate270
        , flipHorizontal
        , flipVertical
        )

import Html exposing (span, Html)
import Html.Attributes exposing (class, attribute)
import List


type Icon
    = Icon
        { base : String
        , size : Size
        , fixedWidth : Bool
        , border : Bool
        , pull : PullDirection
        , spin : SpinType
        , rotation : Rotation
        , ariaHidden : Bool
        }


base : String -> Icon
base class =
    Icon
        { base = class
        , size = Small
        , fixedWidth = False
        , border = False
        , pull = PullNowhere
        , spin = Static
        , rotation = upright
        , ariaHidden = False
        }


type Size
    = Small
    | Large
    | Double
    | Tripple
    | Quadruple
    | Quintuple


setSize : Size -> Icon -> Icon
setSize size (Icon data) =
    Icon { data | size = size }

small : Icon -> Icon
small = setSize Small

large : Icon -> Icon
large = setSize Large

double : Icon -> Icon
double = setSize Double

tripple : Icon -> Icon
tripple = setSize Tripple

quadruple : Icon -> Icon
quadruple = setSize Quadruple

quintuple : Icon -> Icon
quintuple = setSize Quintuple

sizeClass : Size -> Maybe String
sizeClass size =
    case size of
        Small ->
            Nothing

        Large ->
            Just "fa-lg"

        Double ->
            Just "fa-2x"

        Tripple ->
            Just "fa-3x"

        Quadruple ->
            Just "fa-4x"

        Quintuple ->
            Just "fa-5x"


fixWidth : Icon -> Icon
fixWidth (Icon data) =
    Icon { data | fixedWidth = True }


fixedWidthClass : Bool -> Maybe String
fixedWidthClass fix =
    if fix then
        Just "fa-fx"
    else
        Nothing


withBorder : Icon -> Icon
withBorder (Icon data) =
    Icon { data | border = True }


borderClass : Bool -> Maybe String
borderClass border =
    if border then
        Just "fa-border"
    else
        Nothing


type PullDirection
    = PullNowhere
    | PullLeft
    | PullRight


setPull : PullDirection -> Icon -> Icon
setPull pull (Icon data) =
    Icon { data | pull = pull }


pullLeft =
    setPull PullLeft


pullRight =
    setPull PullRight


pullClass : PullDirection -> Maybe String
pullClass pull =
    case pull of
        PullNowhere ->
            Nothing

        PullLeft ->
            Just "fa-pull-left"

        PullRight ->
            Just "fa-pull-right"


type SpinType
    = Static
    | Spinning
    | Pulsing


spinning : Icon -> Icon
spinning (Icon data) =
    Icon { data | spin = Spinning }


pulsing : Icon -> Icon
pulsing (Icon data) =
    Icon { data | spin = Pulsing }


spinClass : SpinType -> Maybe String
spinClass spin =
    case spin of
        Static ->
            Nothing

        Spinning ->
            Just "fa-spin"

        Pulsing ->
            Just "fa-puls"


{-| Unfortunately Font Awesome does not implement the whole Dihedral-4 Group
    (see https://en.wikipedia.org/wiki/Dihedral_group) but only a subset.
    This means the rotation value might no be representable with a class.
    In this case a simmilar class is choosen, where the top of the icon
    points in the correct direction.

    The elements are internally represented as r_i or s_0 after r_i.
-}
type alias Rotation =
    { turn : Int
    , mirrored : Bool
    }


upright : Rotation
upright =
    { turn = 0, mirrored = False }


rotateBy : Int -> Rotation -> Rotation
rotateBy steps rotation =
    { rotation | turn = rotation.turn + steps }


{-| Makes use of the equation r_{ i } s = s r_{ -i }
-}
mirror : Rotation -> Rotation
mirror rotation =
    { turn = -rotation.turn
    , mirrored = not rotation.mirrored
    }


rotationMap : (Rotation -> Rotation) -> Icon -> Icon
rotationMap function (Icon data) =
    Icon { data | rotation = function data.rotation }


rotate90 : Icon -> Icon
rotate90 =
    rotationMap (rotateBy 1)

rotate180 : Icon -> Icon
rotate180 =
    rotationMap (rotateBy 2)

rotate270 : Icon -> Icon
rotate270 =
    rotationMap (rotateBy 3)

flipVertical : Icon -> Icon
flipVertical =
    rotationMap mirror

flipHorizontal : Icon -> Icon
flipHorizontal =
    rotationMap (mirror >> rotateBy 2)


rotationClass : Rotation -> Maybe String
rotationClass rotation =
    case ( rotation.turn % 4, rotation.mirrored ) of
        ( 0, False ) ->
            Nothing

        ( 1, False ) ->
            Just "fa-rotate-90"

        ( 2, False ) ->
            Just "fa-rotate-180"

        ( 3, False ) ->
            Just "fa-rotate-270"

        ( 0, True ) ->
            Just "fa-flip-vertical"

        ( 1, True ) ->
            Just "fa-rotate-90"

        ( 2, True ) ->
            Just "fa-flip-horizontal"

        ( 3, True ) ->
            Just "fa-rotate-270"

        ( _, _ ) ->
            Nothing


hideAria : Icon -> Icon
hideAria (Icon data) =
    Icon { data | ariaHidden = True }


icon : Icon -> Html str
icon (Icon data) =
    span
        [ compileClass
            [ Just data.base
            , sizeClass data.size
            , fixedWidthClass data.fixedWidth
            , borderClass data.border
            , pullClass data.pull
            , spinClass data.spin
            , rotationClass data.rotation
            ]
        , attribute "aria-hidden"
            (if data.ariaHidden then
                "true"
             else
                "false"
            )
        ]
        []


compileClass : List (Maybe String) -> Html.Attribute msg
compileClass classes =
    classes
        |> List.filterMap identity
        |> List.foldl addClass "fa"
        |> class


addClass : String -> String -> String
addClass current new =
    current ++ " " ++ new
