module Frontend.Export exposing (to, toLaTeX, toMarkdown, toRawLaTeX)

import Effect.Command exposing (Command, FrontendOnly)
import Effect.File.Download
import Parser.Language exposing (Language(..))
import Render.Export.LaTeX
import Render.MicroLaTeX
import Render.Settings as Settings
import Render.XMarkdown
import Types exposing (FrontendModel, FrontendMsg, ToBackend)
import Util


to model lang =
    case model.currentDocument of
        Nothing ->
            ( model, Effect.Command.none )

        Just doc ->
            case lang of
                MicroLaTeXLang ->
                    let
                        ast =
                            model.editRecord.parsed

                        newText =
                            Render.MicroLaTeX.export ast
                    in
                    ( model, Effect.File.Download.string "out-microlatex.txt" "text/plain" newText )

                L0Lang ->
                    ( model, Effect.File.Download.string "out-l0.txt" "text/plain" doc.content )

                PlainTextLang ->
                    ( model, Effect.File.Download.string "out-l0.txt" "text/plain" doc.content )

                XMarkdownLang ->
                    let
                        ast =
                            model.editRecord.parsed

                        newText =
                            Render.XMarkdown.export ast
                    in
                    ( model, Effect.File.Download.string "out-xmarkdown.txt" "text/plain" newText )


toLaTeX : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
toLaTeX model =
    let
        textToExport =
            Render.Export.LaTeX.export Settings.defaultSettings model.editRecord.parsed

        fileName =
            (model.currentDocument
                |> Maybe.map .title
                |> Maybe.withDefault "doc"
                |> String.toLower
                |> Util.compressWhitespace
                |> String.replace " " "-"
            )
                ++ ".tex"
    in
    ( model, Effect.File.Download.string fileName "application/x-latex" textToExport )


toRawLaTeX : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
toRawLaTeX model =
    let
        textToExport =
            Render.Export.LaTeX.rawExport Settings.defaultSettings model.editRecord.parsed

        fileName =
            (model.currentDocument
                |> Maybe.map .title
                |> Maybe.withDefault "doc"
                |> String.toLower
                |> Util.compressWhitespace
                |> String.replace " " "-"
            )
                ++ ".tex"
    in
    ( model, Effect.File.Download.string fileName "application/x-latex" textToExport )


toMarkdown : FrontendModel -> ( FrontendModel, Command FrontendOnly ToBackend FrontendMsg )
toMarkdown model =
    let
        markdownText =
            -- TODO:implement this
            -- L1.Render.Markdown.transformDocument model.currentDocument.content
            "Not implemented"

        fileName_ =
            "foo" |> String.replace " " "-" |> String.toLower |> (\name -> name ++ ".md")
    in
    ( model, Effect.File.Download.string fileName_ "text/markdown" markdownText )
