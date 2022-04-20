module View.DocTools exposing (view)

import DateTimeUtility
import Dict exposing (Dict)
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import String.Extra
import Time
import Types exposing (FrontendModel, FrontendMsg, SidebarExtrasState(..), SidebarTagsState(..))
import User
import View.Button as Button
import View.Color as Color
import View.Geometry as Geometry
import View.Input
import View.Style
import View.Utility


view model =
    if model.showDocTools then
        E.column
            [ Background.color Color.mediumPaleBlue
            , E.paddingXY 18 18
            , E.moveUp 302
            , E.spacing 8
            , if model.showEditor then
                E.moveRight (toFloat <| Geometry.appWidth model.sidebarExtrasState model.sidebarTagsState model.windowWidth - 325)

              else
                E.moveRight 605
            , E.width (E.px 300)
            , E.height (E.px 300)
            ]
            [ Button.toggleLock model.currentDocument
            , Button.toggleBackupVisibility model.seeBackups
            , creationDate model
            , dateCreated model.zone model.currentDocument
            , docId model
            ]

    else
        E.none


dateCreated : Time.Zone -> Maybe Document -> E.Element Types.FrontendMsg
dateCreated zone maybeDocument =
    case maybeDocument of
        Nothing ->
            E.none

        Just doc ->
            E.el [ Font.size 14, Background.color Color.paleBlue, E.paddingXY 6 6 ] (E.text (DateTimeUtility.toStringWithYear zone doc.created))


creationDate model =
    backup model.zone model.currentDocument


docId model =
    E.el [ Font.size 12, Background.color Color.paleBlue, E.paddingXY 6 6 ] (Maybe.map .id model.currentDocument |> Maybe.withDefault "" |> E.text)


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
