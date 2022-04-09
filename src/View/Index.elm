module View.Index exposing (view, viewDocuments)

import BoundedDeque
import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Frontend.Update
import String.Extra
import Time
import Types exposing (ActiveDocList(..), DocumentList(..), FrontendModel, FrontendMsg, MaximizedIndex(..), SortMode(..), SystemDocPermissions(..))
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
                    [ E.row [ E.spacing 6, E.alignLeft ]
                        [ Button.getPinnedDocs
                        , Button.openSharedDocumentList model.documentList
                        , Button.toggleDocumentList model.documentList
                        ]
                    , E.row [ E.spacing 6, E.alignRight ]
                        [ Button.setSortModeMostRecent model.sortMode
                        , Button.setSortModeAlpha model.sortMode
                        ]
                    ]
                , case model.documentList of
                    WorkingList ->
                        viewWorkingDocs model deltaH -indexShift

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
            :: viewShareDocuments model.currentDocument model.shareDocumentList
        )


viewShareDocuments : Maybe Document -> List ( String, Types.SharedDocument ) -> List (Element FrontendMsg)
viewShareDocuments currentDocument shareDocumentList =
    List.map (viewSharedDocument currentDocument) shareDocumentList


viewSharedDocument : Maybe Document -> ( String, Types.SharedDocument ) -> Element FrontendMsg
viewSharedDocument currentDocument ( author, sharedDocument ) =
    let
        label =
            author
                ++ ": "
                ++ sharedDocument.title
    in
    Button.getDocument sharedDocument.id (label |> String.Extra.softEllipsis 40) ((Maybe.map .id currentDocument |> Maybe.withDefault "((0))") == sharedDocument.id)


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
                    user_.docs |> BoundedDeque.toList |> sort

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
            :: viewDocInfoList model.currentDocument model.documents docInfoList
        )


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
            sort model.documents

        buttonText =
            "My docs (" ++ String.fromInt (List.length docs) ++ ")"

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
            :: viewDocuments SystemCanEdit model.currentDocument docs
        )


viewPublicDocs model deltaH indexShift =
    let
        buttonText =
            "Published, " ++ model.publicDocumentSearchKey ++ " (" ++ String.fromInt (List.length model.publicDocuments) ++ ")"

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
    viewDocuments SystemReadOnly model.currentDocument (sorter model.publicDocuments)


viewDocuments : SystemDocPermissions -> Maybe Document -> List Document -> List (Element FrontendMsg)
viewDocuments docPermissions currentDocument docs =
    List.map (Button.setDocumentAsCurrent docPermissions currentDocument) docs


viewDocInfoList : Maybe Document -> List Document -> List Document.DocumentInfo -> List (Element FrontendMsg)
viewDocInfoList currentDocument documents docInfoList =
    List.map (\docInfo -> Button.setDocAsCurrentWithDocInfo currentDocument documents docInfo) docInfoList
