module Frontend.Update exposing
    ( newDocument
    , updateCurrentDocument
    , updateWithViewport
    )

import Document exposing (Document)
import Lamdera exposing (sendToBackend)
import Parser.Language exposing (Language(..))
import Types exposing (..)


updateWithViewport vp model =
    let
        w =
            round vp.viewport.width

        h =
            round vp.viewport.height
    in
    ( { model
        | windowWidth = w
        , windowHeight = h
      }
    , Cmd.none
    )


newDocument model =
    let
        emptyDoc =
            Document.empty

        documentsCreatedCounter =
            model.documentsCreatedCounter + 1

        title =
            "New Document (" ++ String.fromInt documentsCreatedCounter ++ ")"

        titleString =
            case model.language of
                L0Lang ->
                    "| title\n" ++ title ++ "\n\n"

                MicroLaTeXLang ->
                    "\\title{" ++ title ++ "}\n\n"

        doc =
            { emptyDoc
                | title = title
                , content = titleString
                , author = Maybe.map .username model.currentUser
                , language = model.language
            }
    in
    ( { model | showEditor = True, documentsCreatedCounter = documentsCreatedCounter }
    , Cmd.batch [ sendToBackend (CreateDocument model.currentUser doc) ]
    )


updateCurrentDocument : Document -> FrontendModel -> FrontendModel
updateCurrentDocument doc model =
    { model | currentDocument = Just doc }
