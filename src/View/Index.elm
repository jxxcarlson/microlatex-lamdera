module View.Index exposing (view, viewDocuments)

import BoundedDeque
import Config
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Frontend.Update
import String.Extra
import Time
import Types exposing (ActiveDocList(..), DocumentHandling(..), DocumentList(..), FrontendModel, FrontendMsg, MaximizedIndex(..), SortMode(..))
import View.Button as Button
import View.Geometry as Geometry
import View.Rendered as Rendered
import View.Utility


view model width_ deltaH =
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
            E.column [ E.spacing 8, E.paddingEach { top = 12, bottom = 0, left = 0, right = 0 } ]
                [ E.row [ E.spacing 18 ]
                    [ E.row [ E.spacing 4, E.alignLeft ]
                        [ View.Utility.hideIf (model.currentUser == Nothing) (Button.pinnedDocs model.documentList)
                        , View.Utility.hideIf (model.currentUser == Nothing) (Button.sharedDocs model.documentList)
                        , View.Utility.hideIf (model.currentUser == Nothing) (Button.workingDocs model.documentList)
                        , Button.standardDocs model.documentList
                        ]
                    , E.row [ E.spacing 4, E.alignRight ]
                        [ Button.setSortModeMostRecent model.sortMode
                        , Button.setSortModeAlpha model.sortMode
                        ]
                    ]
                , case model.documentList of
                    WorkingList ->
                        viewWorkingDocs model deltaH -indexShift

                    PinnedDocs ->
                        viewPinnedDocs model deltaH -indexShift

                    StandardList ->
                        viewMydocs model deltaH -indexShift

                    SharedDocumentList ->
                        viewSharedDocs model deltaH -indexShift
                , viewPublicDocs model deltaH indexShift
                ]

        Just doc ->
            let
                indexShift =
                    150
            in
            E.column [ E.spacing 8 ]
                [ E.row [ E.spacing 8 ] [ Button.setSortModeMostRecent model.sortMode, Button.setSortModeAlpha model.sortMode ]
                , Rendered.viewSmall model doc width_ deltaH indexShift
                , case model.activeDocList of
                    PublicDocsList ->
                        viewPublicDocs model deltaH indexShift

                    PrivateDocsList ->
                        viewMydocs model deltaH indexShift

                    Both ->
                        viewPublicDocs model deltaH indexShift
                ]


viewSharedDocs : FrontendModel -> Int -> Int -> Element FrontendMsg
viewSharedDocs model deltaH indexShift =
    let
        sort =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\docInfo -> String.Extra.ellipsisWith View.Utility.softTruncateLimit " ..." docInfo.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))

        docInfoList =
            case model.currentUser of
                Nothing ->
                    []

                Just user_ ->
                    user_.docs |> BoundedDeque.toList

        buttonText =
            "Working docs (" ++ String.fromInt (List.length docInfoList) ++ ")"

        titleButton =
            Button.toggleActiveDocList buttonText

        -- titleButton
    in
    E.column
        [ E.width (E.px <| Geometry.indexWidth model.windowWidth)
        , E.height (E.px (Geometry.appHeight_ model - deltaH - indexShift))
        , Font.size 14
        , E.scrollbarY
        , Background.color (E.rgb 0.9 0.9 1.0)
        , E.paddingXY 12 18
        , Font.color (E.rgb 0.1 0.1 1.0)
        , E.spacing 8
        ]
        (E.row [ E.spacing 16, E.width E.fill ] [ E.el [ Font.color (E.rgb 0 0 0), Font.bold ] (E.text "Shared documents"), E.el [ E.alignRight ] (View.Utility.showIf (model.currentMasterDocument == Nothing) (Button.maximizeMyDocs model.maximizedIndex)) ]
            :: viewShareDocuments model.currentDocument model.sharedDocumentList
        )


filterBackups seeBackups docs =
    if seeBackups then
        docs

    else
        List.filter (\doc -> doc.handling == Document.DHStandard) docs


viewShareDocuments : Maybe Document -> List ( String, Bool, Types.SharedDocument ) -> List (Element FrontendMsg)
viewShareDocuments currentDocument shareDocumentList =
    List.map (viewSharedDocument currentDocument) shareDocumentList


viewSharedDocument : Maybe Document -> ( String, Bool, Types.SharedDocument ) -> Element FrontendMsg
viewSharedDocument currentDocument ( author, isOnline, sharedDocument ) =
    let
        onlineStatus =
            if isOnline then
                " (online) "

            else
                ""

        label =
            author
                ++ onlineStatus
                ++ ": "
                ++ sharedDocument.title
    in
    Button.getDocument StandardHandling sharedDocument.id (label |> String.Extra.softEllipsis 40) ((Maybe.map .id currentDocument |> Maybe.withDefault "((0))") == sharedDocument.id)


viewWorkingDocs : FrontendModel -> Int -> Int -> Element FrontendMsg
viewWorkingDocs model deltaH indexShift =
    let
        sort =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\docInfo -> String.Extra.ellipsisWith View.Utility.softTruncateLimit " ..." docInfo.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))

        docInfoList =
            case model.currentUser of
                Nothing ->
                    []

                Just user_ ->
                    let
                        foo : BoundedDeque.BoundedDeque Document.DocumentInfo
                        foo =
                            user_.docs
                    in
                    user_.docs |> BoundedDeque.toList |> sort |> filterDocInfo model.seeBackups

        buttonText =
            "Working docs (" ++ String.fromInt (List.length docInfoList) ++ ")"

        titleButton =
            Button.toggleActiveDocList buttonText
    in
    E.column
        [ E.width (E.px <| Geometry.indexWidth model.windowWidth)
        , E.height (E.px (Geometry.appHeight_ model - deltaH - indexShift))
        , Font.size 14
        , E.scrollbarY
        , Background.color (E.rgb 1.0 0.93 0.93)
        , E.paddingXY 12 18
        , Font.color (E.rgb 0.1 0.1 1.0)
        , E.spacing 8
        ]
        (E.row [ E.spacing 16, E.width E.fill ] [ titleButton, E.el [ E.alignRight ] (View.Utility.showIf (model.currentMasterDocument == Nothing) (Button.maximizeMyDocs model.maximizedIndex)) ]
            :: viewDocInfoList model.currentDocument model.documents (docInfoList |> filterDocInfo model.seeBackups)
        )


filterDocInfo : Bool -> List Document.DocumentInfo -> List Document.DocumentInfo
filterDocInfo seeBackups list =
    if seeBackups then
        list

    else
        List.filter (\item -> not (String.contains "BAK" item.title)) list


viewMydocs : FrontendModel -> Int -> Int -> Element FrontendMsg
viewMydocs model deltaH indexShift =
    let
        sort =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\doc -> String.Extra.ellipsisWith View.Utility.softTruncateLimit " ..." doc.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))

        docs =
            sort model.documents |> filterBackups model.seeBackups

        searchKey =
            if model.actualSearchKey == "" then
                " [most recent]"

            else
                " [" ++ model.actualSearchKey ++ "]"

        buttonText =
            case model.currentUser of
                Nothing ->
                    "Startup docs"

                Just _ ->
                    "My docs" ++ searchKey ++ " (" ++ String.fromInt (List.length docs) ++ ")"

        titleButton =
            E.el [ Font.color (E.rgb 0 0 0), Font.size 16 ] (E.text buttonText)
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
            :: viewDocuments StandardHandling model.currentDocument docs
        )


viewPinnedDocs : FrontendModel -> Int -> Int -> Element FrontendMsg
viewPinnedDocs model deltaH indexShift =
    let
        sort =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\doc -> String.Extra.ellipsisWith View.Utility.softTruncateLimit " ..." doc.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))

        docs : List { title : String, id : String, modified : Time.Posix, public : Bool }
        docs =
            sort model.pinnedDocuments

        -- |> filterBackups model.seeBackups
        searchKey =
            "[pin]"

        buttonText =
            "Pinned docs" ++ " (" ++ String.fromInt (List.length docs) ++ ")"

        titleButton =
            E.el [ Font.color (E.rgb 0 0 0), Font.size 16 ] (E.text buttonText)
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
            :: viewDocInfoList model.currentDocument model.documents docs
         --  (docInfoList |> filterDocInfo model.seeBackups)
        )


viewPublicDocs model deltaH indexShift =
    let
        searchKey =
            if model.actualSearchKey == "" then
                Config.publicDocumentStartupSearchKey

            else
                model.actualSearchKey

        buttonText =
            "Public [" ++ searchKey ++ "] (" ++ String.fromInt (List.length model.publicDocuments) ++ ")"

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


viewPublicDocuments : FrontendModel -> List (Element FrontendMsg)
viewPublicDocuments model =
    let
        sorter =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\doc -> String.Extra.ellipsisWith View.Utility.softTruncateLimit " ..." doc.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))
    in
    viewDocuments StandardHandling model.currentDocument (sorter (model.publicDocuments |> filterBackups model.seeBackups))


viewDocuments : DocumentHandling -> Maybe Document -> List Document -> List (Element FrontendMsg)
viewDocuments docHandling currentDocument docs =
    List.map (Button.setDocumentAsCurrent docHandling currentDocument) docs


viewDocInfoList : Maybe Document -> List Document -> List Document.DocumentInfo -> List (Element FrontendMsg)
viewDocInfoList currentDocument documents docInfoList =
    List.map (\docInfo -> Button.setDocAsCurrentWithDocInfo currentDocument documents docInfo) docInfoList
