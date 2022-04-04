module View.Footer exposing (view)

import Document
import Element as E
import Element.Background as Background
import Element.Font as Font
import Message
import Types
import View.Button as Button
import View.Color as Color
import View.Style
import View.Utility


view model width_ =
    E.row
        [ E.spacing 12
        , E.paddingXY 0 8
        , E.height (E.px 35)
        , Background.color Color.black
        , E.width (E.px (width_ + 7))
        , Font.size 14
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
        , E.el [ E.width E.fill ] (messageRow model)
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
        ]
        (model.messages |> List.filter (\m -> List.member m.status [ Types.MSGreen, Types.MSWarning, Types.MSError ]) |> List.map Message.handleMessage)
