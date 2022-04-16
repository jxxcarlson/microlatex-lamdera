module View.Footer exposing (view)

import Document
import Element as E
import Element.Background as Background
import Element.Font as Font
import Message
import Types
import View.Button as Button
import View.Chat
import View.Color as Color
import View.Style
import View.Utility


view model width_ =
    let
        dy =
            if model.showEditor then
                900

            else
                605
    in
    E.row
        [ E.spacing 12
        , E.paddingXY 0 8
        , E.height (E.px 35)
        , Background.color Color.black
        , E.width (E.px (width_ + 7))
        , Font.size 14
        , if model.chatVisible then
            E.inFront
                (E.el
                    [ case model.chatDisplay of
                        Types.TCGDisplay ->
                            E.moveUp 778

                        Types.TCGShowInputForm ->
                            E.moveUp 470
                    , E.moveRight dy
                    ]
                    (View.Chat.view model)
                )

          else
            E.inFront E.none
        ]
        [ -- Button.syncButton
          Button.nextSyncButton model.foundIds
        , Button.exportToLaTeX
        , Button.printToPDF model

        --, Button.exportToMicroLaTeX
        --, Button.exportToXMarkdown
        -- , View.Utility.showIf (isAdmin model) Button.runSpecial
        , View.Utility.showIf (View.Utility.isAdmin model) (Button.toggleAppMode model)

        -- , View.Utility.showIf (isAdmin model) Button.exportJson
        --, View.Utility.showIf (isAdmin model) Button.importJson
        -- , View.Utility.showIf (isAdmin model) (View.Input.specialInput model)
        , E.el [ View.Style.fgWhite, E.paddingXY 8 8, View.Style.bgBlack ] (Maybe.map .id model.currentDocument |> Maybe.withDefault "" |> E.text)
        , showCurrentEditor model.currentDocument
        , View.Utility.showIf (model.currentUser /= Nothing && Maybe.andThen .author model.currentDocument == Maybe.map .username model.currentUser) Button.makeBackup
        , E.el [ E.width E.fill, E.scrollbarX ] (messageRow model)
        ]


showCurrentEditor : Maybe Document.Document -> E.Element msg
showCurrentEditor mDoc =
    let
        message =
            case mDoc of
                Nothing ->
                    "No document"

                Just doc ->
                    case doc.currentEditor of
                        Nothing ->
                            "Editor: nobody"

                        Just username ->
                            "Editor: " ++ username
    in
    E.el [ Font.size 14, Font.color Color.white ] (E.text <| message)


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
