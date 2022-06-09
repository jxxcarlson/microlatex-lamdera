module Parser.Utility exposing (..)

import Parser exposing ((|.), (|=), Parser)
import Parser.Language exposing (Language(..))


l0TitleParser : Parser String
l0TitleParser =
    Parser.succeed (\start end src -> String.slice start end src |> String.dropLeft 8 |> String.trimRight)
        |. Parser.chompUntil "| title "
        |= Parser.getOffset
        |. Parser.chompUntil "\n"
        |= Parser.getOffset
        |= Parser.getSource


microLaTeXTitleParser : Parser String
microLaTeXTitleParser =
    Parser.succeed (\start end src -> String.slice start end src |> String.dropLeft 7)
        |. Parser.chompUntil "\\title{"
        |= Parser.getOffset
        |. Parser.chompUntil "}"
        |= Parser.getOffset
        |= Parser.getSource


parseTitle : Language -> String -> Maybe String
parseTitle lang src =
    case lang of
        L0Lang ->
            case Parser.run l0TitleParser src of
                Ok title ->
                    Just title

                Err _ ->
                    Nothing

        MicroLaTeXLang ->
            case Parser.run microLaTeXTitleParser src of
                Ok title ->
                    Just title

                Err _ ->
                    Nothing

        _ ->
            Nothing
