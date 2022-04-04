module View.Footer exposing (view)

import Element as E
import Element.Background as Background
import Element.Font as Font
import Message
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
        , E.el [ E.width E.fill ] (messageRow model)
        ]


messageRow model =
    E.row
        [ E.width E.fill
        , E.height (E.px 30)
        , E.paddingXY 8 4
        , View.Style.bgGray 0.1
        , View.Style.fgGray 1.0
        ]
        (List.map Message.handleMessage model.messages)
