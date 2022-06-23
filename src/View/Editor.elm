module View.Editor exposing (view)

import CollaborativeEditing.NetworkModel as NetworkModel
import CollaborativeEditing.OTCommand as OTCommand
import Document
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Keyed
import Html
import Html.Attributes as HtmlAttr
import Html.Events
import Json.Decode
import Types exposing (FrontendModel, FrontendMsg(..))
import View.Geometry as Geometry


view : FrontendModel -> Element FrontendMsg
view model =
    Element.Keyed.el
        [ -- RECEIVE INOFRMATION FROM CODEMIRROR
          E.htmlAttribute onSelectionChange -- receive info from codemirror
        , E.htmlAttribute onTextChange -- receive info from codemirror
        , E.htmlAttribute onCursorChange -- receive info from codemirror

        --
        , htmlId "editor-here"
        , E.width (E.px 550)
        , E.height (E.px (Geometry.appHeight model - 110))
        , E.width (E.px (Geometry.panelWidth_ model.sidebarExtrasState model.sidebarTagsState model.windowWidth))
        , Background.color (E.rgb255 0 68 85)
        , Font.color (E.rgb 0.85 0.85 0.85)
        , Font.size 12
        ]
        ( stringOfBool model.showEditor
        , E.html
            (Html.node "codemirror-editor"
                [ -- SEND INFORMATION TO CODEMIRROR
                  HtmlAttr.attribute "text" model.initialText -- send info to codemirror
                , HtmlAttr.attribute "linenumber" (String.fromInt (model.linenumber - 1)) -- send info to codemirror
                , HtmlAttr.attribute "selection" (stringOfBool model.doSync) -- send info to codemirror

                -- , HtmlAttr.attribute "editorevent" (NetworkModel.toString model.editorEvent)
                , HtmlAttr.attribute "editcommand" (OTCommand.toString model.editCommand.counter model.editCommand.command)
                ]
                []
            )
        )



-- EDITOR


stringOfBool bool =
    case bool of
        False ->
            "false"

        True ->
            "true"


htmlId str =
    E.htmlAttribute (HtmlAttr.id str)


onCursorChange : Html.Attribute FrontendMsg
onCursorChange =
    dataDecoder
        |> Json.Decode.map InputCursor
        |> Html.Events.on "cursor-change"


cursorDecoder : Json.Decode.Decoder Int
cursorDecoder =
    cursorDecoder_
        |> Json.Decode.at [ "detail" ]


cursorDecoder_ : Json.Decode.Decoder Int
cursorDecoder_ =
    Json.Decode.field "position" Json.Decode.int


onTextChange : Html.Attribute FrontendMsg
onTextChange =
    dataDecoder
        |> Json.Decode.map InputText
        |> Html.Events.on "text-change"


onSelectionChange : Html.Attribute FrontendMsg
onSelectionChange =
    textDecoder
        |> Json.Decode.map SelectedText
        |> Html.Events.on "selected-text"


dataDecoder : Json.Decode.Decoder Document.SourceTextRecord
dataDecoder =
    dataDecoder_
        |> Json.Decode.at [ "detail" ]


dataDecoder_ : Json.Decode.Decoder Document.SourceTextRecord
dataDecoder_ =
    Json.Decode.map2 Document.SourceTextRecord
        (Json.Decode.field "position" Json.Decode.int)
        (Json.Decode.field "source" Json.Decode.string)


textDecoder : Json.Decode.Decoder String
textDecoder =
    Json.Decode.string
        |> Json.Decode.at [ "detail" ]
