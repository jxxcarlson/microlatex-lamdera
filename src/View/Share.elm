module View.Share exposing (view)

import Document
import Element as E
import Element.Background as Background
import Element.Font as Font
import Types exposing (FrontendModel, PopupState(..))
import User
import View.Button as Button
import View.Color as Color
import View.Input
import View.Utility


view : FrontendModel -> E.Element Types.FrontendMsg
view model =
    if userIsTheAuthor model && model.popupState == SharePopup then
        updateSharingStatus model

    else if userIsReaderOrEditor model && model.popupState == SharePopup then
        viewSharingStatus model

    else
        E.none


viewSharingStatus : FrontendModel -> E.Element Types.FrontendMsg
viewSharingStatus model =
    let
        ( readers_, editors_ ) =
            case model.currentDocument of
                Nothing ->
                    ( "", "" )

                Just doc ->
                    case doc.share of
                        Document.Private ->
                            ( "", "" )

                        Document.Share { readers, editors } ->
                            ( readers |> String.join ", ", editors |> String.join ", " )
    in
    E.column
        style
        [ E.el [ E.spacing 18, E.paddingEach { top = 0, bottom = 20, left = 0, right = 0 } ] (E.el [ Font.bold, Font.size 18 ] (E.text "Sharing status"))
        , E.column [ E.spacing 8 ] [ label "Readers", E.paragraph statusStyle [ E.text readers_ ] ]
        , E.column [ E.spacing 8 ] [ label "Editors", E.paragraph statusStyle [ E.text editors_ ] ]
        , E.row [ E.spacing 12, E.paddingEach { top = 30, bottom = 0, left = 0, right = 0 } ] [ Button.dismissPopup ]
        ]


statusStyle =
    [ Background.color Color.white
    , E.paddingXY 12 12
    , E.width (E.px 400)
    , E.height (E.px 100)
    ]


style =
    [ E.moveRight 150
    , E.moveDown 40
    , E.spacing 18
    , E.width (E.px 500)
    , E.height (E.px 700)
    , E.padding 20
    , Font.size 14
    , Background.color Color.paleViolet
    ]


updateSharingStatus : FrontendModel -> E.Element Types.FrontendMsg
updateSharingStatus model =
    E.column
        style
        [ E.el [ E.paddingEach { top = 0, bottom = 20, left = 0, right = 0 } ] (E.el [ Font.bold, Font.size 18 ] (E.text "Share your document"))
        , E.column [ E.spacing 8 ] [ label "Readers", View.Input.readers 400 200 model ]
        , E.column [ E.spacing 8 ] [ label "Editors", View.Input.editors 400 200 model ]
        , E.row [ E.spacing 12, E.paddingEach { top = 30, bottom = 0, left = 0, right = 0 } ] [ Button.doShare, Button.dismissPopup ]
        ]


userIsTheAuthor model =
    case model.currentDocument of
        Nothing ->
            False

        Just doc ->
            Maybe.andThen .author model.currentDocument == Maybe.map .username model.currentUser


userIsReaderOrEditor model =
    case model.currentDocument of
        Nothing ->
            False

        Just doc ->
            View.Utility.isShared model.currentUser doc


label str =
    E.el [ Font.size 16, Font.bold, E.width (E.px 60) ] (E.text str)
