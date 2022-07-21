module Frontend.Navigation exposing (respondToUrlChange, urlAction)

import Config
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Types
import UrlManager
import Util


respondToUrlChange model url =
    let
        cmd =
            if String.left 3 url.path == "/c/" then
                Util.delay 1 (Types.SetDocumentCurrentViaId (String.dropLeft 3 url.path))

            else
                UrlManager.handleDocId url
    in
    ( { model | url = url }, cmd )


urlAction : String -> Command FrontendOnly Types.ToBackend Types.FrontendMsg
urlAction path =
    let
        prefix =
            String.left 3 path

        segment =
            String.dropLeft 3 path
    in
    if prefix == "/" then
        Effect.Lamdera.sendToBackend (Types.GetDocumentById Types.StandardHandling Config.welcomeDocId)

    else
        case prefix of
            "/i/" ->
                Effect.Lamdera.sendToBackend (Types.GetDocumentById Types.StandardHandling segment)

            "/a/" ->
                Effect.Lamdera.sendToBackend (Types.SearchForDocumentsWithAuthorAndKey segment)

            "/s/" ->
                Effect.Lamdera.sendToBackend (Types.SearchForDocuments Types.StandardHandling Nothing segment)

            "/h/" ->
                Effect.Lamdera.sendToBackend (Types.GetHomePage segment)

            _ ->
                --Process.sleep 500 |> Task.perform (always (SetPublicDocumentAsCurrentById id))
                Effect.Lamdera.sendToBackend (Types.GetDocumentById Types.StandardHandling Config.welcomeDocId)
