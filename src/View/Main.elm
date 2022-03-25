module View.Main exposing (view)

import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Render.Markup
import Render.Settings
import Render.TOC
import Time
import Types exposing (ActiveDocList(..), AppMode(..), DocPermissions(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), SidebarState(..), SortMode(..))
import View.Admin as Admin
import View.Button as Button
import View.Color as Color
import View.Editor as Editor
import View.Footer as Footer
import View.Geometry as Geometry
import View.Header as Header
import View.Input
import View.Sidebar as Sidebar
import View.Style as Style
import View.Utility


type alias Model =
    FrontendModel


view : Model -> Html FrontendMsg
view model =
    E.layoutWith { options = [ E.focusStyle View.Utility.noFocus ] }
        [ Style.bgGray 0.9, E.clipX, E.clipY ]
        (viewMainColumn model)


viewMainColumn : Model -> Element FrontendMsg
viewMainColumn model =
    case model.appMode of
        AdminMode ->
            Admin.view model

        UserMode ->
            if model.showEditor then
                viewEditorAndRenderedText model

            else
                viewRenderedTextOnly model



-- TOP


viewEditorAndRenderedText : Model -> Element FrontendMsg
viewEditorAndRenderedText model =
    let
        deltaH =
            (Geometry.appHeight_ model - 100) // 2 + 130
    in
    E.column (Style.mainColumn model)
        [ E.column [ E.spacing 12, E.centerX, E.width (E.px <| Geometry.appWidth model.sidebarState model.windowWidth), E.height (E.px (Geometry.appHeight_ model)) ]
            [ Header.view model (E.px <| Geometry.appWidth model.sidebarState model.windowWidth)
            , E.row [ E.spacing 12 ]
                [ Editor.view model
                , viewRenderedForEditor model (Geometry.panelWidth_ model.sidebarState model.windowWidth)
                , viewIndex model (Geometry.appWidth model.sidebarState model.windowWidth) deltaH
                , Sidebar.view model
                ]
            , Footer.view model (Geometry.appWidth model.sidebarState model.windowWidth)
            ]
        ]



-- MIDDLE


viewRenderedTextOnly : Model -> Element FrontendMsg
viewRenderedTextOnly model =
    let
        deltaH =
            (Geometry.appHeight_ model - 100) // 2 + 130
    in
    E.column (Style.mainColumn model)
        [ E.column [ E.centerX, E.spacing 12, E.width (E.px <| Geometry.smallAppWidth model.windowWidth), E.height (E.px (Geometry.appHeight_ model)) ]
            [ Header.view model (E.px <| Geometry.smallHeaderWidth model.windowWidth)
            , E.row [ E.spacing 12 ]
                [ viewRenderedContainer model
                , viewIndex model (Geometry.smallAppWidth model.windowWidth) deltaH
                , Sidebar.view model
                ]
            , Footer.view model (Geometry.smallHeaderWidth model.windowWidth)
            ]
        ]


viewIndex model width_ deltaH =
    case model.currentMasterDocument of
        Nothing ->
            let
                indexShift =
                    case model.maximizedIndex of
                        MMyDocs ->
                            150

                        MPublicDocs ->
                            -150
            in
            E.column [ E.spacing 8 ]
                [ E.row [ E.spacing 12 ] [ Button.setSortModeMostRecent model.sortMode, Button.setSortModeAlpha model.sortMode ]
                , viewMydocs model deltaH -indexShift
                , viewPublicDocs model deltaH indexShift
                ]

        Just doc ->
            let
                indexShift =
                    150
            in
            E.column [ E.spacing 8 ]
                [ E.row [ E.spacing 8 ] [ Button.setSortModeMostRecent model.sortMode, Button.setSortModeAlpha model.sortMode ]
                , viewRenderedSmall model doc width_ deltaH indexShift
                , case model.activeDocList of
                    PublicDocsList ->
                        viewPublicDocs model deltaH indexShift

                    PrivateDocsList ->
                        viewMydocs model deltaH indexShift

                    Both ->
                        viewPublicDocs model deltaH indexShift
                ]


viewRenderedContainer model =
    E.column [ E.spacing 18 ]
        [ viewRendered model (Geometry.smallPanelWidth model.windowWidth)
        ]


viewMydocs : Model -> Int -> Int -> Element FrontendMsg
viewMydocs model deltaH indexShift =
    let
        sort =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\doc -> View.Utility.softTruncate View.Utility.softTruncateLimit doc.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))

        docs =
            sort model.documents

        buttonText =
            "My docs (" ++ String.fromInt (List.length docs) ++ ")"

        titleButton =
            Button.toggleActiveDocList buttonText
    in
    E.column
        [ E.width (E.px <| Geometry.indexWidth model.windowWidth)
        , E.height (E.px (Geometry.appHeight_ model - deltaH - indexShift))
        , Font.size 14
        , E.scrollbarY
        , Background.color (E.rgb 0.95 0.95 1.0)
        , E.paddingXY 12 18
        , Font.color (E.rgb 0.1 0.1 1.0)
        , E.spacing 8
        ]
        (E.row [ E.spacing 16, E.width E.fill ] [ titleButton, E.el [ E.alignRight ] (View.Utility.showIf (model.currentMasterDocument == Nothing) (Button.maximizeMyDocs model.maximizedIndex)) ]
            :: viewDocumentsInIndex CanEdit model.currentDocument docs
        )


viewDocumentsInIndex : DocPermissions -> Maybe Document -> List Document -> List (Element FrontendMsg)
viewDocumentsInIndex docPermissions currentDocument docs =
    List.map (Button.setDocumentAsCurrent docPermissions currentDocument) docs


viewPublicDocs model deltaH indexShift =
    let
        buttonText =
            "Published docs (" ++ String.fromInt (List.length model.publicDocuments) ++ ")"

        titleButton =
            Button.toggleActiveDocList buttonText
    in
    E.column
        [ E.width (E.px <| Geometry.indexWidth model.windowWidth)
        , E.height (E.px (Geometry.appHeight_ model - deltaH - indexShift))
        , Font.size 14
        , E.scrollbarY
        , Background.color (E.rgb 0.95 0.95 1.0)
        , E.paddingXY 12 18
        , Font.color (E.rgb 0.1 0.1 1.0)
        , E.spacing 8
        ]
        (E.row [ E.spacing 16, E.width E.fill ] [ titleButton, E.el [ E.alignRight ] (View.Utility.showIf (model.currentMasterDocument == Nothing) (Button.maximizePublicDocs model.maximizedIndex)) ]
            :: viewPublicDocuments model
        )


currentAuthor : Maybe Document -> String
currentAuthor maybeDoc =
    case maybeDoc of
        Nothing ->
            ""

        Just doc ->
            doc.author |> Maybe.withDefault ""


viewRenderedSmall : Model -> Document -> Int -> Int -> Int -> Element FrontendMsg
viewRenderedSmall model doc width_ deltaH indexShift =
    let
        editRecord =
            Compiler.DifferentialParser.init doc.language doc.content

        currentDocId =
            Maybe.map .id model.currentDocument |> Maybe.withDefault "???"
    in
    E.column
        [ E.paddingEach { left = 12, right = 12, top = 18, bottom = 96 }
        , Style.bgGray 1.0
        , E.width (E.px <| Geometry.indexWidth model.windowWidth)
        , E.height (E.px (Geometry.appHeight_ model - deltaH + indexShift))
        , Font.size 14
        , E.alignTop
        , E.scrollbarY
        , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
        ]
        [ View.Utility.katexCSS
        , E.column [ E.spacing 4, E.width (E.px (Geometry.indexWidth model.windowWidth - 20)) ]
            (viewDocumentSmall (affine 1.75 -650 (Geometry.indexWidth model.windowWidth)) model.counter currentDocId editRecord)

        -- (viewDocumentSmall (Geometry.indexWidth model.windowWidth) model.counter currentDocId editRecord)
        ]


viewRendered : Model -> Int -> Element FrontendMsg
viewRendered model width_ =
    case model.currentDocument of
        Nothing ->
            E.none

        Just _ ->
            E.column
                [ E.paddingEach { left = 24, right = 24, top = 32, bottom = 96 }
                , Style.bgGray 1.0
                , E.width (E.px width_)
                , E.height (E.px (Geometry.panelHeight_ model))
                , Font.size 14
                , E.alignTop
                , E.scrollbarY
                , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument (affine 1.75 -650 (Geometry.panelWidth2_ model.sidebarState model.windowWidth)) model.counter model.selectedId model.editRecord)
                ]


viewDocumentSmall windowWidth counter currentDocId editRecord =
    let
        title_ : Element FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s ->
                        E.paragraph
                            [ E.htmlAttribute (HtmlAttr.id "title")
                            , Font.size 16
                            , E.paddingEach { top = 0, bottom = 12, left = 0, right = 0 }
                            ]
                            [ E.text s ]
                   )

        body : List (Element FrontendMsg)
        body =
            Render.Markup.renderFromAST counter editRecord.accumulator (renderSettings currentDocId windowWidth) editRecord.parsed |> List.map (E.map Render)
    in
    E.row [ E.spacing 16, E.width E.fill ] [ title_, E.el [ E.moveUp 6, E.alignRight, E.paddingEach { left = 0, right = 8, top = 0, bottom = 0 } ] Button.closeCollectionsIndex ] :: body


viewDocument windowWidth counter selectedId editRecord =
    let
        title_ : Element FrontendMsg
        title_ =
            Compiler.ASTTools.title editRecord.parsed
                |> (\s -> E.paragraph [ E.htmlAttribute (HtmlAttr.id "title"), Font.size Config.titleSize ] [ E.text s ])

        toc : Element FrontendMsg
        toc =
            Render.TOC.view counter editRecord.accumulator (renderSettings selectedId windowWidth |> setSelectedId selectedId) editRecord.parsed |> E.map Render

        body : List (Element FrontendMsg)
        body =
            Render.Markup.renderFromAST counter editRecord.accumulator (renderSettings selectedId windowWidth) editRecord.parsed |> List.map (E.map Render)
    in
    title_ :: toc :: body


viewRenderedForEditor : Model -> Int -> Element FrontendMsg
viewRenderedForEditor model width_ =
    case model.currentDocument of
        Nothing ->
            E.none

        Just _ ->
            E.column
                [ E.paddingEach { left = 24, right = 24, top = 32, bottom = 96 }
                , Style.bgGray 1.0
                , E.width (E.px width_)
                , E.height (E.px (Geometry.panelHeight_ model))
                , Font.size 14
                , E.alignTop
                , E.scrollbarY
                , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument (affine 1.8 0 (Geometry.panelWidth_ model.sidebarState model.windowWidth)) model.counter model.selectedId model.editRecord)
                ]


affine : Float -> Float -> Int -> Int
affine a b x =
    a * toFloat x + b |> truncate


setSelectedId : String -> Render.Settings.Settings -> Render.Settings.Settings
setSelectedId id settings =
    { settings | selectedId = id }


renderSettings : String -> Int -> Render.Settings.Settings
renderSettings id w =
    Render.Settings.makeSettings id 0.38 w


viewPublicDocuments : Model -> List (Element FrontendMsg)
viewPublicDocuments model =
    let
        sorter =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\doc -> View.Utility.softTruncate View.Utility.softTruncateLimit doc.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))
    in
    viewDocumentsInIndex ReadOnly model.currentDocument (sorter model.publicDocuments)
