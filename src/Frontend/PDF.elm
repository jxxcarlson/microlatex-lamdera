module Frontend.PDF exposing (gotLink, print)

import Compiler.ASTTools as ASTTools
import Config
import Document exposing (Document)
import Duration
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.File.Download
import Effect.Http
import Effect.Process
import Effect.Task
import Either
import Json.Encode as E
import Markup
import Maybe.Extra
import Parser.Block exposing (ExpressionBlock(..))
import Render.Export.LaTeX
import Render.Settings
import Tree
import Types exposing (FrontendModel, FrontendMsg(..), MessageStatus(..), PrintingState(..))


print model =
    case model.currentDocument of
        Nothing ->
            ( model, Command.none )

        Just doc ->
            ( { model | messages = [ { txt = "printToPDF", status = MSGreen } ] }
            , Command.batch
                [ generatePdf doc
                , Effect.Process.sleep (Duration.milliseconds 1) |> Effect.Task.perform (always (ChangePrintingState PrintProcessing))
                ]
            )


generatePdf : Document -> Command FrontendOnly toMsg FrontendMsg
generatePdf document =
    let
        syntaxTree =
            Markup.parse document.language document.content

        imageUrls : List String
        imageUrls =
            syntaxTree
                |> List.map Tree.flatten
                |> List.concat
                |> List.map (\(ExpressionBlock { content }) -> Either.toList content)
                |> List.concat
                |> List.concat
                |> ASTTools.filterExpressionsOnName "image"
                |> List.map (ASTTools.getText >> Maybe.map String.trim)
                |> List.map (Maybe.andThen extractUrl)
                |> Maybe.Extra.values

        contentForExport =
            Render.Export.LaTeX.export Render.Settings.defaultSettings syntaxTree
    in
    Command.batch
        [ Effect.Http.request
            { method = "POST"
            , headers = [ Effect.Http.header "Content-Type" "application/json" ]
            , url = Config.pdfServer ++ "/pdf"
            , body = Effect.Http.jsonBody (encodeForPDF document.id contentForExport imageUrls)
            , expect = Effect.Http.expectString GotPdfLink
            , timeout = Nothing
            , tracker = Nothing
            }
        , Effect.File.Download.string "export.tex" "application/x-latex" contentForExport
        ]


extractUrl : String -> Maybe String
extractUrl str =
    str |> String.split " " |> List.head


gotLink : FrontendModel -> Result error value -> ( FrontendModel, Command restriction toMsg FrontendMsg )
gotLink model result =
    case result of
        Err _ ->
            ( model, Command.none )

        Ok _ ->
            ( model
            , Command.batch
                [ Effect.Process.sleep (Duration.milliseconds 5) |> Effect.Task.perform (always (ChangePrintingState PrintReady))
                ]
            )


encodeForPDF : String -> String -> List String -> E.Value
encodeForPDF id content urlList =
    E.object
        [ ( "id", E.string id )
        , ( "content", E.string content )
        , ( "urlList", E.list E.string urlList )
        ]


encodeForPDF1 : String -> String -> String -> List String -> E.Value
encodeForPDF1 id title content urlList =
    E.object
        [ ( "id", E.string id )
        , ( "content", E.string content )
        , ( "urlList", E.list E.string urlList )
        ]
