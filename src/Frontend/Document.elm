module Frontend.Document exposing (changeLanguage, makeBackup)

import Document
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Frontend.Update
import Types


changeLanguage : Types.FrontendModel -> ( Types.FrontendModel, Command FrontendOnly Types.ToBackend Types.FrontendMsg )
changeLanguage model =
    case model.currentDocument of
        Nothing ->
            ( model, Effect.Command.none )

        Just doc ->
            let
                newDocument =
                    { doc | language = model.language }
            in
            ( model
            , Effect.Lamdera.sendToBackend (Types.SaveDocument model.currentUser newDocument)
            )
                |> (\( m, c ) -> ( Frontend.Update.postProcessDocument newDocument m, c ))


makeBackup model =
    case ( model.currentUser, model.currentDocument ) of
        ( Nothing, _ ) ->
            ( model, Effect.Command.none )

        ( _, Nothing ) ->
            ( model, Effect.Command.none )

        ( Just user, Just doc ) ->
            if Just user.username == doc.author then
                let
                    newDocument =
                        Document.makeBackup doc
                in
                ( model, Effect.Lamdera.sendToBackend (Types.InsertDocument user newDocument) )

            else
                ( model, Effect.Command.none )
