module View.Phone exposing (view)

import Config
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Font as Font
import Html exposing (Html)
import Render.Markup
import Render.Settings
import Render.TOC
import Types exposing (DocumentHandling(..), FrontendModel, FrontendMsg(..), PhoneMode(..))
import View.Button as Button
import View.Input
import View.Style
import View.Utility


type alias Model =
    FrontendModel


view : Model -> Html FrontendMsg
view model =
    E.layoutWith { options = [ E.focusStyle View.Utility.noFocus ] }
        [ View.Style.bgGray 0.9, E.clipX, E.clipY ]
        (case model.phoneMode of
            PMShowDocument ->
                E.column []
                    [ E.row [ E.height (E.px 40), E.paddingXY 12 2, Font.size 14 ] [ Button.showTOCInPhone ]
                    , viewRendered model (smallPanelWidth model.windowWidth)
                    ]

            PMShowDocumentList ->
                E.column []
                    [ header model (E.px <| smallPanelWidth model.windowWidth)
                    , E.column
                        [ E.paddingEach { left = 0, right = 0, top = 0, bottom = 20 }
                        , View.Style.bgGray 1.0
                        , E.width (E.px <| smallPanelWidth model.windowWidth)
                        , E.height (E.px (appHeight_ model))
                        , Font.size 14
                        , E.spacing 8
                        , E.alignTop
                        , E.paddingXY 15 15
                        , E.scrollbarY
                        ]
                        (viewPublicDocuments model)
                    ]
        )



-- TOP
--


viewDocumentsInIndex : DocumentHandling -> Maybe Document -> List Document -> List (Element FrontendMsg)
viewDocumentsInIndex docPermissions currentDocument docs =
    List.map (Button.setDocumentInPhoneAsCurrent docPermissions currentDocument) docs


currentAuthor : Maybe Document -> String
currentAuthor maybeDoc =
    case maybeDoc of
        Nothing ->
            ""

        Just doc ->
            doc.author |> Maybe.withDefault ""


viewRendered : Model -> Int -> Element FrontendMsg
viewRendered model width_ =
    case model.currentDocument of
        Nothing ->
            E.none

        Just _ ->
            E.column
                [ E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 }
                , View.Style.bgGray 1.0
                , E.width (E.px width_)
                , E.height (E.px (appHeight_ model))
                , Font.size 14
                , E.alignTop
                , E.scrollbarY
                , E.clipX
                , View.Utility.elementAttribute "id" Config.renderedTextId
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px width_), E.paddingXY 16 32 ]
                    ((Render.TOC.view model.counter model.editRecord.accumulator (renderSettings model.selectedId model.windowWidth) model.editRecord.parsed |> E.map Render)
                        :: (Render.Markup.renderFromAST model.counter model.editRecord.accumulator (renderSettings model.selectedId (round <| 2.5 * toFloat model.windowWidth)) model.editRecord.parsed |> List.map (E.map Render))
                    )
                ]


viewPublicDocuments : Model -> List (Element FrontendMsg)
viewPublicDocuments model =
    viewDocumentsInIndex StandardHandling model.currentDocument model.publicDocuments


header model _ =
    E.row [ E.spacing 12, E.width E.fill ]
        [ View.Input.searchDocsInput model
        , E.el [ Font.size 14, Font.color (E.rgb 0.9 0.9 0.9) ] (E.text (currentAuthor model.currentDocument))

        -- , E.el [ E.alignRight ] (title Config.appName)
        ]


renderSettings : String -> Int -> Render.Settings.Settings
renderSettings id w =
    Render.Settings.makeSettings id Nothing 0.38 w



--compile : Language -> Int -> Settings -> List String -> List (Element msg)
--compile language generation settings lines
-- DIMENSIONS


innerGutter =
    12



-- BOTTOM


smallPanelWidth ww =
    smallAppWidth ww - innerGutter


smallAppWidth ww =
    -- ramp 700 1000 ww
    ww


appHeight_ model =
    model.windowHeight
