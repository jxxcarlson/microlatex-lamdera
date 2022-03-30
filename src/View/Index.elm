module View.Index exposing (view, viewDocuments)

import Document exposing (Document)
import Element as E exposing (Element)
import Element.Background as Background
import Element.Font as Font
import Time
import Types exposing (ActiveDocList(..), DocPermissions(..), FrontendModel, FrontendMsg, MaximizedIndex(..), SortMode(..))
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


viewMydocs : FrontendModel -> Int -> Int -> Element FrontendMsg
viewMydocs model deltaH indexShift =
    let
        sort =
            case model.sortMode of
                SortAlphabetically ->
                    List.sortBy (\doc -> View.Utility.softTruncate View.Utility.softTruncateLimit doc.title)

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
            :: viewDocuments CanEdit model.currentDocument docs
        )


viewPublicDocs model deltaH indexShift =
    let
        buttonText =
            "Published docs (" ++ String.fromInt (List.length model.publicDocuments) ++ ")"

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
                    List.sortBy (\doc -> View.Utility.softTruncate View.Utility.softTruncateLimit doc.title)

                SortByMostRecent ->
                    List.sortWith (\a b -> compare (Time.posixToMillis b.modified) (Time.posixToMillis a.modified))
    in
    viewDocuments ReadOnly model.currentDocument (sorter model.publicDocuments)


viewDocuments : DocPermissions -> Maybe Document -> List Document -> List (Element FrontendMsg)
viewDocuments docPermissions currentDocument docs =
    List.map (Button.setDocumentAsCurrent docPermissions currentDocument) docs
