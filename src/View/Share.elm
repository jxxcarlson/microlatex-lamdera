module View.Share exposing (usermessage, view)

import Document
import Element as E
import Element.Background as Background
import Element.Font as Font
import Types exposing (FrontendModel, PopupState(..), SystemDocPermissions(..))
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


usermessage : Maybe Types.UserMessage -> E.Element Types.FrontendMsg
usermessage mUserMessage =
    case mUserMessage of
        Nothing ->
            E.none

        Just message ->
            let
                showButton : Types.UMButtons -> E.Element Types.FrontendMsg -> E.Element Types.FrontendMsg
                showButton umButton element =
                    if List.member umButton message.show then
                        element

                    else
                        E.none
            in
            E.column [ E.padding 20, E.spacing 12, E.width (E.px 300), E.height (E.px 400), Background.color Color.paleBlue ]
                [ row "From:" message.from
                , row "To:" message.to
                , row "Subject:" message.subject
                , row "Message:" message.content
                , E.row [ E.spacing 36 ]
                    [ showButton Types.UMOk <|
                        Button.reply "Ok"
                            { from = message.to
                            , to = message.from
                            , subject = message.subject
                            , content = "Ok!"
                            , show = [ Types.UMDismiss, Types.UMUnlock ]
                            , action = Types.UnLockCurrentDocument
                            , actionOnFailureToDeliver = Types.FANoOp
                            }
                    , showButton Types.UMNotYet <|
                        Button.reply "Not just yet"
                            { from = message.to
                            , to = message.from
                            , subject = message.subject
                            , content = "Not just yet"
                            , show = [ Types.UMDismiss ]
                            , action = Types.FENoOp
                            , actionOnFailureToDeliver = Types.FANoOp
                            }
                    ]
                , if List.member Types.UMUnlock message.show then
                    Button.unlock

                  else
                    Button.dismissUserMessage
                ]


usermessageReply : Maybe Types.UserMessage -> E.Element Types.FrontendMsg
usermessageReply mUserMessage =
    case mUserMessage of
        Nothing ->
            E.none

        Just message ->
            E.column [ E.padding 20, E.spacing 12, E.width (E.px 300), E.height (E.px 400), Background.color Color.paleBlue ]
                [ row "From:" message.from
                , row "To:" message.to
                , row "Subject:" message.subject
                , row "Message:" message.content
                , Button.dismissUserMessage
                ]


row heading body =
    E.row [ E.spacing 12, Font.size 14 ]
        [ E.el [ Font.bold, E.width (E.px 60) ] (E.text heading)
        , E.paragraph [ E.width (E.px 250) ] [ E.text body ]
        ]


viewSharingStatus : FrontendModel -> E.Element Types.FrontendMsg
viewSharingStatus model =
    let
        ( readers_, editors_ ) =
            View.Utility.getReadersAndEditors model.currentDocument

        docAuthor =
            Maybe.andThen .author model.currentDocument |> Maybe.withDefault "???"

        docTitle =
            Maybe.map .title model.currentDocument |> Maybe.withDefault "???"

        panelTitle =
            docTitle ++ " (shared by " ++ docAuthor ++ ")"
    in
    E.column
        style
        [ E.el [ E.spacing 18, E.paddingEach { top = 0, bottom = 20, left = 0, right = 0 } ] (E.el [ Font.bold, Font.size 18 ] (E.text panelTitle))
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


updateSharingStatus : FrontendModel -> E.Element Types.FrontendMsg
updateSharingStatus model =
    E.column
        style2
        [ E.el [ E.paddingEach { top = 0, bottom = 20, left = 0, right = 0 } ] (E.el [ Font.bold, Font.size 18 ] (E.text <| "Share " ++ currentDocTitle model))
        , E.column [ E.spacing 8 ] [ label "Readers", View.Input.readers 400 200 model ]
        , E.column [ E.spacing 8 ] [ label "Editors", View.Input.editors 400 200 model ]
        , E.row [ E.spacing 12, E.paddingEach { top = 30, bottom = 0, left = 0, right = 0 } ] [ Button.doShare, Button.dismissPopup ]
        ]


style2 =
    [ E.moveRight 128
    , E.moveDown 25
    , E.spacing 18
    , E.width (E.px 450)
    , E.height (E.px 700)
    , E.padding 25
    , Font.size 14
    , Background.color Color.paleGreen
    ]


style =
    [ E.moveRight 128
    , E.moveDown 25
    , E.spacing 18
    , E.width (E.px 450)
    , E.height (E.px 700)
    , E.padding 25
    , Font.size 14
    , Background.color Color.paleViolet
    ]


currentDocTitle : FrontendModel -> String
currentDocTitle model =
    case model.currentDocument of
        Nothing ->
            ""

        Just doc ->
            doc.title


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
            View.Utility.isSharedToMe model.currentUser doc


label str =
    E.el [ Font.size 16, Font.bold, E.width (E.px 60) ] (E.text str)
