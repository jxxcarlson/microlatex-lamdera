module View.Editor exposing (view)

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
        [ E.htmlAttribute onSelectionChange -- receive info from codemirror
        , E.htmlAttribute onTextChange -- receive info from codemirror
        , htmlId "editor-here"
        , E.width (E.px 550)
        , E.height (E.px (Geometry.appHeight_ model - 110))
        , E.width (E.px (Geometry.panelWidth_ model.sidebarExtrasState model.windowWidth))
        , Background.color (E.rgb255 0 68 85)
        , Font.color (E.rgb 0.85 0.85 0.85)
        , Font.size 12
        ]
        ( stringOfBool model.showEditor
        , E.html
            (Html.node "codemirror-editor"
                [ HtmlAttr.attribute "text" model.initialText -- send info to codemirror
                , HtmlAttr.attribute "linenumber" (String.fromInt (model.linenumber - 1)) -- send info to codemirror
                , HtmlAttr.attribute "selection" (stringOfBool model.doSync) -- send info to codemirror
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


onTextChange : Html.Attribute FrontendMsg
onTextChange =
    textDecoder
        |> Json.Decode.map InputText
        |> Html.Events.on "text-change"


onSelectionChange : Html.Attribute FrontendMsg
onSelectionChange =
    textDecoder
        |> Json.Decode.map SelectedText
        |> Html.Events.on "selected-text"


textDecoder : Json.Decode.Decoder String
textDecoder =
    Json.Decode.string
        |> Json.Decode.at [ "detail" ]
