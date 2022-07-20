module Render.Math exposing (DisplayMode(..), mathText)

import Element exposing (Element)
import Html exposing (Html)
import Html.Attributes as HA
import Html.Keyed
import Json.Encode
import Parser.TextMacro


type DisplayMode
    = InlineMathMode
    | DisplayMathMode


mathText : Int -> String -> String -> DisplayMode -> String -> Element msg
mathText generation width id displayMode content =
    -- the code 'String.replace "\\ \\" "\\\\"'
    -- is needed because for some reason "\\\\" gets expanded to "\\ \\"
    -- TODO Track this down at the source.
    Html.Keyed.node "span"
        [ HA.style "padding-top" "14px"
        , HA.style "padding-bottom" "14px"
        , HA.id id
        , HA.style "width" width
        ]
        [ ( String.fromInt generation, mathText_ displayMode (eraseLabeMacro content) )
        ]
        |> Element.html


eraseLabeMacro content =
    content |> String.lines |> List.map (Parser.TextMacro.eraseLeadingMacro "label") |> String.join "\n"


mathText_ : DisplayMode -> String -> Html msg
mathText_ displayMode content =
    Html.node "math-text"
        -- active meta selectedId  ++
        [ HA.property "display" (Json.Encode.bool (isDisplayMathMode displayMode))
        , HA.property "content" (Json.Encode.string content)

        -- , clicker meta
        -- , HA.id (makeId meta)
        ]
        []


isDisplayMathMode : DisplayMode -> Bool
isDisplayMathMode displayMode =
    case displayMode of
        InlineMathMode ->
            False

        DisplayMathMode ->
            True
