module View.Main exposing (view)

import Compiler.ASTTools
import Compiler.DifferentialParser
import Config
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Element.Keyed
import Html exposing (Html)
import Html.Attributes as HtmlAttr
import Html.Events
import Json.Decode
import Render.Markup
import Render.Settings
import Render.TOC
import String.Extra
import Time
import Types exposing (ActiveDocList(..), AppMode(..), DocPermissions(..), FrontendModel, FrontendMsg(..), MaximizedIndex(..), SortMode(..))
import View.Button as Button
import View.Color as Color
import View.Input
import View.Style
import View.Utility


type alias Model =
    FrontendModel


view : Model -> Html FrontendMsg
view model =
    E.layoutWith { options = [ E.focusStyle View.Utility.noFocus ] }
        [ View.Style.bgGray 0.9, E.clipX, E.clipY ]
        (mainColumn model)


mainColumn : Model -> Element FrontendMsg
mainColumn model =
    case model.appMode of
        AdminMode ->
            viewAdmin model

        UserMode ->
            if model.showEditor then
                viewEditorAndRenderedText model

            else
                viewRenderedTextOnly model



-- TOP


viewAdmin : Model -> Element FrontendMsg
viewAdmin model =
    E.column (mainColumnStyle model)
        [ E.column [ E.spacing 12, E.centerX, E.width (E.px <| appWidth model.windowWidth), E.height (E.px (appHeight_ model)) ]
            [ header model (E.px <| appWidth model.windowWidth)
            , E.row [ E.spacing 12 ]
                [ View.Utility.showIf (isAdmin model) (View.Input.specialInput model)
                , Button.runSpecial
                , Button.toggleAppMode model
                , Button.exportJson
                , View.Utility.showIf (isAdmin model) Button.importJson
                ]
            , footer model (appWidth model.windowWidth)
            ]
        ]


viewEditorAndRenderedText : Model -> Element FrontendMsg
viewEditorAndRenderedText model =
    let
        deltaH =
            (appHeight_ model - 100) // 2 + 130
    in
    E.column (mainColumnStyle model)
        [ E.column [ E.spacing 12, E.centerX, E.width (E.px <| appWidth model.windowWidth), E.height (E.px (appHeight_ model)) ]
            [ header model (E.px <| appWidth model.windowWidth)
            , E.row [ E.spacing 12 ]
                [ editor_ model
                , viewRenderedForEditor model (panelWidth_ model.windowWidth)
                , viewIndex model (appWidth model.windowWidth) deltaH
                ]
            , footer model (appWidth model.windowWidth)
            ]
        ]


editor_ : Model -> Element FrontendMsg
editor_ model =
    Element.Keyed.el
        [ E.htmlAttribute onSelectionChange -- receive info from codemirror
        , E.htmlAttribute onTextChange -- receive info from codemirror
        , htmlId "editor-here"
        , E.width (E.px 550)
        , E.height (E.px (appHeight_ model - 110))
        , E.width (E.px (panelWidth_ model.windowWidth))
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



-- MIDDLE


viewRenderedTextOnly : Model -> Element FrontendMsg
viewRenderedTextOnly model =
    let
        deltaH =
            (appHeight_ model - 100) // 2 + 130
    in
    E.column (mainColumnStyle model)
        [ E.column [ E.centerX, E.spacing 12, E.width (E.px <| smallAppWidth model.windowWidth), E.height (E.px (appHeight_ model)) ]
            [ header model (E.px <| smallHeaderWidth model.windowWidth)
            , E.row [ E.spacing 12 ]
                [ viewRenderedContainer model
                , viewIndex model (smallAppWidth model.windowWidth) deltaH
                ]
            , footer model (smallHeaderWidth model.windowWidth)
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
                [ E.row [ E.spacing 12 ] [ Button.setSortModeMostRecent model.sortMode, Button.setSortModeAlpha model.sortMode ]
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
        [ viewRendered model (smallPanelWidth model.windowWidth)
        ]


viewMydocs : Model -> Int -> Int -> Element FrontendMsg
viewMydocs model deltaH indexShift =
    let
        sort =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\doc -> softTruncate softTruncateLimit doc.title)

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
        [ E.width (E.px <| indexWidth model.windowWidth)
        , E.height (E.px (appHeight_ model - deltaH - indexShift))
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
        [ E.width (E.px <| indexWidth model.windowWidth)
        , E.height (E.px (appHeight_ model - deltaH - indexShift))
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


footer model _ =
    E.row
        [ E.spacing 12
        , E.paddingXY 0 8
        , E.height (E.px 25)
        , E.width E.fill -- (E.px width_)
        , Font.size 14
        ]
        [ -- Button.syncButton
          Button.nextSyncButton model.foundIds
        , Button.exportToLaTeX
        , Button.printToPDF model
        , Button.exportToMicroLaTeX
        , Button.exportToXMarkdown

        -- , View.Utility.showIf (isAdmin model) Button.runSpecial
        , View.Utility.showIf (isAdmin model) (Button.toggleAppMode model)

        -- , View.Utility.showIf (isAdmin model) Button.exportJson
        --, View.Utility.showIf (isAdmin model) Button.importJson
        -- , View.Utility.showIf (isAdmin model) (View.Input.specialInput model)
        , E.el [ View.Style.fgWhite, E.paddingXY 8 8, View.Style.bgBlack ] (Maybe.map .id model.currentDocument |> Maybe.withDefault "" |> E.text)
        , E.el [ E.width E.fill, rightPaddingFooter model.showEditor ] (messageRow model)
        ]


rightPaddingFooter showEditor =
    case showEditor of
        True ->
            E.paddingEach { left = 0, right = 22, top = 0, bottom = 0 }

        False ->
            E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 }


isAdmin : Model -> Bool
isAdmin model =
    Maybe.map .username model.currentUser == Just "jxxcarlson"


messageRow model =
    E.row
        [ E.width E.fill
        , E.height (E.px 30)
        , E.paddingXY 8 4
        , View.Style.bgGray 0.1
        , View.Style.fgGray 1.0
        ]
        [ E.text model.message ]


header model _ =
    E.row [ E.spacing 12, E.width E.fill ]
        [ View.Utility.hideIf (model.currentUser == Nothing) (Button.cycleLanguage model.language)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.showIf model.showEditor Button.closeEditor)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.hideIf model.showEditor Button.openEditor)
        , View.Utility.hideIf (model.currentUser == Nothing) Button.newDocument
        , View.Utility.hideIf (model.currentUser == Nothing) (Button.deleteDocument model)
        , View.Utility.hideIf (model.currentUser == Nothing) (Button.cancelDeleteDocument model)
        , View.Utility.hideIf (model.currentUser == Nothing) (View.Utility.showIf model.showEditor (Button.togglePublic model.currentDocument))
        , View.Utility.showIf model.showEditor (wordCount model)

        --, E.el [ Font.size 14, Font.color (E.rgb 0.9 0.9 0.9) ] (E.text (currentAuthor model.currentDocument))
        , View.Input.searchDocsInput model
        , Button.iLink Config.welcomeDocId "Home"
        , View.Utility.showIf (model.currentUser == Nothing) Button.signIn
        , View.Utility.showIf (model.currentUser == Nothing) (View.Input.usernameInput model)
        , View.Utility.showIf (model.currentUser == Nothing) (View.Input.passwordInput model)
        , Button.signOut model

        -- , Button.help
        , E.el [ E.alignRight, rightPaddingHeader model.showEditor ] (title Config.appName)
        ]


rightPaddingHeader showEditor =
    case showEditor of
        True ->
            E.paddingEach { left = 0, right = 30, top = 0, bottom = 0 }

        False ->
            E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 }


currentAuthor : Maybe Document -> String
currentAuthor maybeDoc =
    case maybeDoc of
        Nothing ->
            ""

        Just doc ->
            doc.author |> Maybe.withDefault ""


wordCount : Model -> Element FrontendMsg
wordCount model =
    case model.currentDocument of
        Nothing ->
            E.none

        Just doc ->
            E.el [ Font.size 14, Font.color Color.lightGray ] (E.text <| "words: " ++ (String.fromInt <| Document.wordCount doc))


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
        , View.Style.bgGray 1.0
        , E.width (E.px <| indexWidth model.windowWidth)
        , E.height (E.px (appHeight_ model - deltaH + indexShift))
        , Font.size 14
        , E.alignTop
        , E.scrollbarY
        , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
        ]
        [ View.Utility.katexCSS
        , E.column [ E.spacing 4, E.width (E.px (indexWidth model.windowWidth - 20)) ]
            (viewDocumentSmall (affine 1.75 -650 (indexWidth model.windowWidth)) model.counter currentDocId editRecord)

        -- (viewDocumentSmall (indexWidth model.windowWidth) model.counter currentDocId editRecord)
        ]


viewRendered : Model -> Int -> Element FrontendMsg
viewRendered model width_ =
    case model.currentDocument of
        Nothing ->
            E.none

        Just _ ->
            E.column
                [ E.paddingEach { left = 24, right = 24, top = 32, bottom = 96 }
                , View.Style.bgGray 1.0
                , E.width (E.px width_)
                , E.height (E.px (panelHeight_ model))
                , Font.size 14
                , E.alignTop
                , E.scrollbarY
                , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument (affine 1.75 -650 (panelWidth2_ model.windowWidth)) model.counter model.selectedId model.editRecord)
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
                , View.Style.bgGray 1.0
                , E.width (E.px width_)
                , E.height (E.px (panelHeight_ model))
                , Font.size 14
                , E.alignTop
                , E.scrollbarY
                , View.Utility.elementAttribute "id" "__RENDERED_TEXT__"
                ]
                [ View.Utility.katexCSS
                , E.column [ E.spacing 18, E.width (E.px (width_ - 60)) ]
                    (viewDocument (affine 1.8 0 (panelWidth_ model.windowWidth)) model.counter model.selectedId model.editRecord)
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
                    List.sortBy (\doc -> softTruncate softTruncateLimit doc.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))
    in
    viewDocumentsInIndex ReadOnly model.currentDocument (sorter model.publicDocuments)


softTruncateLimit =
    50


softTruncate : Int -> String -> String
softTruncate k str =
    case String.Extra.softBreak k str of
        [] ->
            ""

        str2 :: [] ->
            str2

        str2 :: _ ->
            str2 ++ " ..."



-- DIMENSIONS


innerGutter =
    12


outerGutter =
    12


panelWidth_ : Int -> Int
panelWidth_ ww =
    (appWidth ww - indexWidth ww) // 2 - innerGutter - outerGutter


panelWidth2_ : Int -> Int
panelWidth2_ ww =
    appWidth ww - indexWidth ww - innerGutter



-- BOTTOM


smallPanelWidth ww =
    smallAppWidth ww - indexWidth ww - innerGutter


smallHeaderWidth ww =
    smallAppWidth ww


indexWidth : number -> number
indexWidth ww =
    ramp 150 300 ww


appWidth ww =
    ramp 700 1400 ww


smallAppWidth ww =
    ramp 700 900 ww


ramp a b x =
    if x < a then
        a

    else if x > b then
        b

    else
        x


appHeight_ model =
    model.windowHeight - 40


panelHeight_ model =
    appHeight_ model - 110


mainColumnStyle model =
    [ View.Style.bgGray 0.5
    , E.paddingEach { top = 40, bottom = 20, left = 0, right = 0 }
    , E.width (E.px model.windowWidth)
    , E.height (E.px model.windowHeight)
    ]


title : String -> Element msg
title str =
    E.row [ E.centerX, View.Style.fgGray 0.9 ] [ E.text str ]
