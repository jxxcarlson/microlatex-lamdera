module Frontend.Documentation exposing (toggleGuides, toggleManuals)

import Config
import Document
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Parser.Language exposing (Language(..))
import Types


toggleGuides : Types.FrontendModel -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
toggleGuides model =
    case model.popupState of
        Types.NoPopup ->
            let
                id =
                    case model.language of
                        L0Lang ->
                            Config.l0GuideId

                        MicroLaTeXLang ->
                            Config.microLaTeXGuideId

                        XMarkdownLang ->
                            Config.xmarkdownGuideId

                        PlainTextLang ->
                            Config.plainTextCheatsheetId
            in
            ( { model | popupState = Types.GuidesPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual id) )

        _ ->
            ( { model | popupState = Types.NoPopup }, Effect.Command.none )


toggleManuals model manualType =
    case model.popupState of
        Types.NoPopup ->
            toggleManualsNoPopup model manualType

        Types.ManualsPopup ->
            case manualType of
                Types.TManual ->
                    toggleManualsManuals model

                Types.TGuide ->
                    toggleGuides_ model

        _ ->
            ( { model | popupState = Types.NoPopup }, Effect.Command.none )


toggleManualsNoPopup model manualType =
    case manualType of
        Types.TManual ->
            case model.language of
                L0Lang ->
                    ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.l0ManualId) )

                MicroLaTeXLang ->
                    ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.microLaTeXManualId) )

                XMarkdownLang ->
                    ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.xmarkdownId) )

                PlainTextLang ->
                    ( { model | popupState = Types.NoPopup }, Effect.Command.none )

        Types.TGuide ->
            case model.language of
                L0Lang ->
                    ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.l0GuideId) )

                MicroLaTeXLang ->
                    ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.microLaTeXGuideId) )

                XMarkdownLang ->
                    ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.xmarkdownGuideId) )

                PlainTextLang ->
                    ( { model | popupState = Types.NoPopup }, Effect.Command.none )


toggleManualsManuals model =
    if
        List.member (Maybe.andThen Document.getSlug model.currentManual)
            [ Just Config.l0ManualId, Just Config.microLaTeXManualId, Just Config.microLaTeXManualId ]
    then
        ( { model | popupState = Types.NoPopup }, Effect.Command.none )

    else
        case model.language of
            L0Lang ->
                ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.l0ManualId) )

            MicroLaTeXLang ->
                ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.microLaTeXManualId) )

            XMarkdownLang ->
                ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.xmarkdownId) )

            PlainTextLang ->
                ( { model | popupState = Types.NoPopup }, Effect.Command.none )


toggleGuides_ model =
    if
        List.member (Maybe.andThen Document.getSlug model.currentManual)
            [ Just Config.l0GuideId, Just Config.microLaTeXGuideId, Just Config.microLaTeXGuideId ]
    then
        ( { model | popupState = Types.NoPopup }, Effect.Command.none )

    else
        case model.language of
            L0Lang ->
                ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.l0GuideId) )

            MicroLaTeXLang ->
                ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.microLaTeXGuideId) )

            XMarkdownLang ->
                ( { model | popupState = Types.ManualsPopup }, Effect.Lamdera.sendToBackend (Types.FetchDocumentById Types.HandleAsManual Config.xmarkdownGuideId) )

            PlainTextLang ->
                ( { model | popupState = Types.NoPopup }, Effect.Command.none )
