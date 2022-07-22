module Frontend.Export exposing (to)

import Effect.Command
import Effect.File.Download
import Parser.Language exposing (Language(..))
import Render.MicroLaTeX
import Render.XMarkdown


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
