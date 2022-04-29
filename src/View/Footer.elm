module View.Footer exposing (view)

import Config
import DateTimeUtility
import Document exposing (Document)
import Element as E
import Element.Background as Background
import Element.Font as Font
import Message
import Predicate
import Time
import Types
import View.Button as Button
import View.Chat
import View.Color as Color
import View.DocTools
import View.Geometry as Geometry
import View.Style
import View.Utility


view model width_ =
    let
        dy =
            if model.showEditor then
                Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth - 370

            else
                Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth - 800
    in
    E.row
        [ E.spacing 1
        , E.inFront (View.DocTools.view model)
        , E.inFront (View.DocTools.urlPopup model)
        , E.paddingXY 8 8
        , E.height (E.px 35)
        , Background.color Color.black
        , E.width (E.px (width_ + 7))
        , Font.size 14
        , if model.chatVisible then
            E.inFront
                (E.el
                    [ case model.chatDisplay of
                        Types.TCGDisplay ->
                            E.moveUp 738

                        Types.TCGShowInputForm ->
                            E.moveUp 738
                    , E.moveRight (toFloat dy)
                    ]
                    (View.Chat.view model)
                )

          else
            E.inFront E.none
        ]
        [ -- Button.syncButton
          Button.nextSyncButton model.foundIds
        , View.Utility.showIf (model.currentUser /= Nothing)
            (E.row [ E.spacing 1 ]
                [ View.Utility.showIf (Predicate.documentIsMineOrSharedToMe model.currentDocument model.currentUser) Button.exportToLaTeX
                , Button.printToPDF model
                ]
            )

        --, Button.exportToMicroLaTeX
        --, Button.exportToXMarkdown
        -- , View.Utility.showIf (isAdmin model) Button.runSpecial
        , View.Utility.showIf (View.Utility.isAdmin model) (Button.toggleAppMode model)

        -- , View.Utility.showIf (isAdmin model) Button.exportJson
        --, View.Utility.showIf (isAdmin model) Button.importJson
        -- , View.Utility.showIf (isAdmin model) (View.Input.specialInput model)
        --, showCurrentEditor model.currentDocument
        , View.Utility.showIf (Predicate.documentIsMineOrSharedToMe model.currentDocument model.currentUser) (Button.toggleDocumentStatus model)
        , View.Utility.showIf (Predicate.documentIsMineOrSharedToMe model.currentDocument model.currentUser) (isCurrentDocumentDirty model.documentDirty)
        , View.Utility.showIf (Predicate.documentIsMineOrSharedToMe model.currentDocument model.currentUser) (timeElapsed model)
        , E.el [ E.paddingXY 12 0 ] (showCurrentEditors model.currentDocument)
        , E.el [ E.width E.fill, E.scrollbarX ] (messageRow model)
        , E.el [ E.alignRight, E.moveUp 6 ] Button.togglePublicUrl
        , View.Utility.showIf (Predicate.documentIsMineOrSharedToMe model.currentDocument model.currentUser) (E.el [ E.alignRight, E.moveUp 6 ] (Button.toggleDocTools model))
        ]


isCurrentDocumentDirty dirty =
    if dirty then
        E.el [ Font.color (E.rgb 1 0 0) ] (E.text "dirty")

    else
        E.el [ Font.color (E.rgb 0 1 0) ] (E.text "clean")


timeElapsed model =
    let
        elapsedSinceLastInteraction : Int
        elapsedSinceLastInteraction =
            (Time.posixToMillis model.currentTime - Time.posixToMillis model.lastInteractionTime) // 1000
    in
    if elapsedSinceLastInteraction < Config.automaticSignoutLimit - Config.automaticSignoutNoticePeriod then
        --E.el [ Font.color Color.white ] (E.text (String.fromInt elapsedSinceLastInteraction))
        E.none

    else
        let
            timeRemaining =
                String.fromInt (1 + Config.automaticSignoutLimit - elapsedSinceLastInteraction)

            message =
                "Automatic signout in " ++ timeRemaining ++ " seconds. Type any key to cancel."
        in
        E.el [ Font.color Color.white, Background.color Color.red, E.paddingXY 8 4 ] (E.text message)


backup : Time.Zone -> Maybe Document -> E.Element Types.FrontendMsg
backup zone maybeDocument =
    case maybeDocument of
        Nothing ->
            E.none

        Just doc ->
            case doc.handling of
                Document.DHStandard ->
                    Button.makeBackup

                Document.Backup _ ->
                    E.el [ Background.color Color.paleBlue, E.paddingXY 6 6 ] (E.text (DateTimeUtility.toStringWithYear zone doc.created))

                Document.Version _ _ ->
                    E.el [ Background.color Color.paleBlue, E.paddingXY 6 6 ] (E.text (DateTimeUtility.toStringWithYear zone doc.created))


showCurrentEditors : Maybe Document.Document -> E.Element msg
showCurrentEditors mDoc =
    let
        message =
            case mDoc of
                Nothing ->
                    "No document"

                Just doc ->
                    "Editors: " ++ (doc.currentEditors |> List.map .username |> String.join ", ")
    in
    E.el [ Font.size 14, Font.color Color.paleGreen ] (E.text <| message)


messageRow model =
    E.row
        [ E.width E.fill
        , E.height (E.px 30)
        , E.paddingXY 8 4
        , View.Style.bgGray 0.1
        , View.Style.fgGray 1.0
        , E.spacing 12
        ]
        (model.messages |> List.filter (\m -> List.member m.status [ Types.MSGreen, Types.MSYellow, Types.MSRed ]) |> List.map Message.handleMessage)
