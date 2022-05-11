module View.Utility exposing
    ( addTooltip
    , cssNode
    , currentDocumentAuthor
    , currentDocumentEditor
    , elementAttribute
    , getElementWithViewPort
    , getReadersAndEditors
    , hideIf
    , htmlId
    , isAdmin
    , katexCSS
    , noFocus
    , onEnter
    , setViewPortForSelectedLine
    , setViewPortToTop
    , setViewportForElement
    , showIf
    , softTruncateLimit
    , truncateString
    , viewId
    )

import Browser.Dom as Dom
import Config
import Document
import Element as E exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events exposing (keyCode, on)
import Json.Decode as D
import Predicate
import Task exposing (Task)
import Types exposing (FrontendModel, FrontendMsg)
import User
import View.Color as Color


htmlId str =
    E.htmlAttribute (HA.id str)


isAdmin : FrontendModel -> Bool
isAdmin model =
    Maybe.map .username model.currentUser == Just "jxxcarlson"


softTruncateLimit =
    50


getReadersAndEditors : Maybe Document.Document -> ( String, String )
getReadersAndEditors mDocument =
    case mDocument of
        Nothing ->
            ( "", "" )

        Just doc ->
            ( doc.sharedWith.readers |> String.join ", ", doc.sharedWith.editors |> String.join ", " )


currentDocumentAuthor : Maybe String -> Maybe Document.Document -> Element FrontendMsg
currentDocumentAuthor mUsername mDoc =
    case mDoc of
        Nothing ->
            E.none

        Just doc ->
            let
                color =
                    if mUsername == doc.author then
                        if doc.sharedWith.readers == [] && doc.sharedWith.editors == [] then
                            -- my doc, not shared
                            Font.color (E.rgb 0.5 0.5 1.0)

                        else
                            -- my doc, shared to someone
                            Font.color (E.rgb 0.5 0.8 0.8)

                    else if Predicate.isSharedToMe_ mUsername doc then
                        -- not my doc, shared to me
                        Font.color (E.rgb 0.9 0.8 0.6)

                    else
                        -- not my doc, not shared to me
                        Font.color (E.rgb 0.9 0.9 0.9)

                nowEditing =
                    doc.currentEditorList |> List.map .username |> String.join ", "

                str =
                    Maybe.andThen .author mDoc |> Maybe.map (\x -> "a: " ++ x) |> Maybe.withDefault ""
            in
            E.el [ color, Font.size 14 ] (E.text str)


currentDocumentEditor : Maybe String -> Maybe Document.Document -> Element FrontendMsg
currentDocumentEditor mUsername mDoc =
    case mDoc of
        Nothing ->
            E.none

        Just doc ->
            let
                color =
                    if mUsername == doc.author then
                        if doc.sharedWith.readers == [] && doc.sharedWith.editors == [] then
                            -- my doc, not shared
                            Font.color (E.rgb 0.5 0.5 1.0)

                        else
                            -- my doc, shared to someone
                            Font.color (E.rgb 0.5 0.8 0.8)

                    else if Predicate.isSharedToMe_ mUsername doc then
                        -- not my doc, shared to me
                        Font.color (E.rgb 0.9 0.8 0.6)

                    else
                        -- not my doc, not shared to me
                        Font.color (E.rgb 0.9 0.9 0.9)

                nowEditing =
                    doc.currentEditorList |> List.map .username |> String.join ", "
            in
            E.el [ color, Font.size 14 ] (E.text nowEditing)


truncateString : Int -> String -> String
truncateString k str =
    let
        str2 =
            truncateString_ k str
    in
    if str == str2 then
        str

    else
        str2 ++ " ..."


truncateString_ : Int -> String -> String
truncateString_ k str =
    if String.length str < k then
        str

    else
        let
            words =
                String.words str

            n =
                List.length words
        in
        words
            |> List.take (n - 1)
            |> String.join " "
            |> truncateString_ k


onEnter : FrontendMsg -> Html.Attribute FrontendMsg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                D.succeed msg

            else
                D.fail "not ENTER"
    in
    on "keydown" (keyCode |> D.andThen isEnter)


showIf : Bool -> Element msg -> Element msg
showIf isVisible element =
    if isVisible then
        element

    else
        E.none


hideIf : Bool -> Element msg -> Element msg
hideIf condition element =
    if condition then
        E.none

    else
        element


viewId : Types.PopupState -> String
viewId popupState =
    case popupState of
        Types.CheatSheetPopup ->
            Config.cheatSheetRenderedTextId

        _ ->
            Config.renderedTextId


setViewportForElement : String -> String -> Cmd FrontendMsg
setViewportForElement viewId_ elementId =
    Dom.getViewportOf viewId_
        |> Task.andThen (\vp -> getElementWithViewPort vp elementId)
        |> Task.attempt Types.SetViewPortForElement


setViewPortToTop : Types.PopupState -> Cmd FrontendMsg
setViewPortToTop popupState =
    case popupState of
        Types.CheatSheetPopup ->
            Task.attempt (\_ -> Types.NoOpFrontendMsg) (Dom.setViewportOf Config.cheatSheetRenderedTextId 0 0)

        _ ->
            Task.attempt (\_ -> Types.NoOpFrontendMsg) (Dom.setViewportOf Config.renderedTextId 0 0)


setViewPortForSelectedLine : Types.PopupState -> Dom.Element -> Dom.Viewport -> Cmd FrontendMsg
setViewPortForSelectedLine popupState element viewport =
    let
        y =
            -- viewport.viewport.y + element.element.y - element.element.height - 380
            viewport.viewport.y + element.element.y - element.element.height - 380
    in
    case popupState of
        Types.CheatSheetPopup ->
            Task.attempt (\_ -> Types.NoOpFrontendMsg) (Dom.setViewportOf Config.cheatSheetRenderedTextId 0 y)

        _ ->
            Task.attempt (\_ -> Types.NoOpFrontendMsg) (Dom.setViewportOf Config.renderedTextId 0 y)


getElementWithViewPort : Dom.Viewport -> String -> Task Dom.Error ( Dom.Element, Dom.Viewport )
getElementWithViewPort vp id =
    Dom.getElement id
        |> Task.map (\el -> ( el, vp ))


noFocus : E.FocusStyle
noFocus =
    { borderColor = Nothing
    , backgroundColor = Nothing
    , shadow = Nothing
    }


cssNode : String -> Element FrontendMsg
cssNode fileName =
    Html.node "link" [ HA.rel "stylesheet", HA.href fileName ] [] |> E.html



-- Include KaTeX CSS


katexCSS : Element FrontendMsg
katexCSS =
    E.html <|
        Html.node "link"
            [ HA.attribute "rel" "stylesheet"
            , HA.attribute "href" "https://cdn.jsdelivr.net/npm/katex@0.15.1/dist/katex.min.css"
            ]
            []


elementAttribute : String -> String -> E.Attribute msg
elementAttribute key value =
    E.htmlAttribute (HA.attribute key value)


myTooltip : String -> Element msg
myTooltip str =
    E.el
        [ Background.color (E.rgb 0 0 0)
        , Font.color (E.rgb 1 1 1)
        , E.padding 4
        , Border.rounded 5
        , Font.size 14
        , Border.shadow
            { offset = ( 0, 3 ), blur = 6, size = 0, color = E.rgba 0 0 0 0.32 }
        ]
        (E.text str)



--


tooltip : (Element msg -> E.Attribute msg) -> Element Never -> E.Attribute msg
tooltip usher tooltip_ =
    E.inFront <|
        E.el
            [ E.width E.fill
            , E.height E.fill
            , E.transparent True
            , E.mouseOver [ E.transparent False ]
            , (usher << E.map never) <|
                E.el
                    [ E.htmlAttribute (HA.style "pointerEvents" "none") ]
                    tooltip_
            ]
            E.none



-- addTooltip : (Element msg -> E.Attribute msg) -> String -> E.Element -> E.Element


addTooltip placement label element =
    E.el
        [ tooltip placement (myTooltip label) ]
        element



-- el [ tooltip below (myTooltip "bar") ] (text "bar")
