module View.Utility exposing
    ( canSave
    , canSaveStrict
    , cssNode
    , currentDocumentAuthor
    , currentDocumentEditor
    , elementAttribute
    , getElementWithViewPort
    , getReadersAndEditors
    , hideIf
    , htmlId
    , iOwnThisDocument
    , iOwnThisDocument_
    , isAdmin
    , isSharedToMe
    , isSharedToMe_
    , isShared_
    , isUnlocked
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
import Element exposing (Element)
import Element.Font as Font
import Html
import Html.Attributes as HA
import Html.Events exposing (keyCode, on)
import Json.Decode as D
import String.Extra
import Task exposing (Task)
import Types exposing (FrontendModel, FrontendMsg)
import User


htmlId str =
    Element.htmlAttribute (HA.id str)


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
            case doc.share of
                Document.NotShared ->
                    ( "", "" )

                Document.ShareWith { readers, editors } ->
                    ( readers |> String.join ", ", editors |> String.join ", " )


isUnlocked : Document.Document -> Bool
isUnlocked doc =
    doc.currentEditor == Nothing


canSave : Maybe User.User -> Document.Document -> Bool
canSave mCurrentUser currentDocument =
    let
        iOwntheDocOrItIsShareToMe =
            Maybe.map .username mCurrentUser
                == .author currentDocument
                || isSharedToMe_ (Maybe.map .username mCurrentUser) currentDocument

        iAmTheCurrentEditorOrNobodyIs =
            Maybe.map .username mCurrentUser == currentDocument.currentEditor || currentDocument.currentEditor == Nothing
    in
    iOwntheDocOrItIsShareToMe && iAmTheCurrentEditorOrNobodyIs


canSaveStrict : Maybe User.User -> Document.Document -> Bool
canSaveStrict mCurrentUser currentDocument =
    let
        mUsername =
            Maybe.map .username mCurrentUser
    in
    if isShared_ mUsername currentDocument then
        currentDocument.currentEditor == mUsername

    else
        iOwnThisDocument_ (mUsername |> Maybe.withDefault "((nobody))") currentDocument


iOwnThisDocument : Maybe User.User -> Document.Document -> Bool
iOwnThisDocument mUser doc =
    Maybe.map .username mUser == doc.author


iOwnThisDocument_ : String -> Document.Document -> Bool
iOwnThisDocument_ username doc =
    Just username == doc.author


isSharedToMe : Maybe User.User -> Document.Document -> Bool
isSharedToMe mUser doc =
    case mUser of
        Nothing ->
            False

        Just user ->
            case doc.share of
                Document.NotShared ->
                    False

                Document.ShareWith { readers, editors } ->
                    List.member user.username readers || List.member user.username editors


isSharedToMe_ : Maybe String -> Document.Document -> Bool
isSharedToMe_ mUsername doc =
    case mUsername of
        Nothing ->
            False

        Just username ->
            case doc.share of
                Document.NotShared ->
                    False

                Document.ShareWith { readers, editors } ->
                    List.member username readers || List.member username editors


isShared_ : Maybe String -> Document.Document -> Bool
isShared_ mUsername doc =
    case mUsername of
        Nothing ->
            False

        Just username ->
            case doc.share of
                Document.NotShared ->
                    False

                Document.ShareWith { readers, editors } ->
                    List.isEmpty readers && List.isEmpty editors |> not


currentDocumentAuthor : Maybe String -> Maybe Document.Document -> Element FrontendMsg
currentDocumentAuthor mUsername mDoc =
    case mDoc of
        Nothing ->
            Element.none

        Just doc ->
            let
                color =
                    if mUsername == doc.author then
                        if doc.share == Document.NotShared then
                            -- my doc, not shared
                            Font.color (Element.rgb 0.5 0.5 1.0)

                        else
                            -- my doc, shared to someone
                            Font.color (Element.rgb 0.5 0.8 0.8)

                    else if isSharedToMe_ mUsername doc then
                        -- not my doc, shared to me
                        Font.color (Element.rgb 0.9 0.8 0.6)

                    else
                        -- not my doc, not shared to me
                        Font.color (Element.rgb 0.9 0.9 0.9)

                nowEditing =
                    case doc.currentEditor of
                        Nothing ->
                            ""

                        Just editorName ->
                            " , editing: " ++ editorName

                str =
                    Maybe.andThen .author mDoc |> Maybe.map (\x -> "a: " ++ x) |> Maybe.withDefault ""
            in
            Element.el [ color, Font.size 14 ] (Element.text str)


currentDocumentEditor : Maybe String -> Maybe Document.Document -> Element FrontendMsg
currentDocumentEditor mUsername mDoc =
    case mDoc of
        Nothing ->
            Element.none

        Just doc ->
            let
                color =
                    if mUsername == doc.author then
                        if doc.share == Document.NotShared then
                            -- my doc, not shared
                            Font.color (Element.rgb 0.5 0.5 1.0)

                        else
                            -- my doc, shared to someone
                            Font.color (Element.rgb 0.5 0.8 0.8)

                    else if isSharedToMe_ mUsername doc then
                        -- not my doc, shared to me
                        Font.color (Element.rgb 0.9 0.8 0.6)

                    else
                        -- not my doc, not shared to me
                        Font.color (Element.rgb 0.9 0.9 0.9)

                nowEditing =
                    case doc.currentEditor of
                        Nothing ->
                            ""

                        Just editorName ->
                            "editing: " ++ editorName
            in
            Element.el [ color, Font.size 14 ] (Element.text nowEditing)


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
        Element.none


hideIf : Bool -> Element msg -> Element msg
hideIf condition element =
    if condition then
        Element.none

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


noFocus : Element.FocusStyle
noFocus =
    { borderColor = Nothing
    , backgroundColor = Nothing
    , shadow = Nothing
    }


cssNode : String -> Element FrontendMsg
cssNode fileName =
    Html.node "link" [ HA.rel "stylesheet", HA.href fileName ] [] |> Element.html



-- Include KaTeX CSS


katexCSS : Element FrontendMsg
katexCSS =
    Element.html <|
        Html.node "link"
            [ HA.attribute "rel" "stylesheet"
            , HA.attribute "href" "https://cdn.jsdelivr.net/npm/katex@0.15.1/dist/katex.min.css"
            ]
            []


elementAttribute : String -> String -> Element.Attribute msg
elementAttribute key value =
    Element.htmlAttribute (HA.attribute key value)
