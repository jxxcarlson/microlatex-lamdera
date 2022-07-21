module UrlManager exposing (handleDocId)

import Effect.Command as Command exposing (Command)
import Effect.Lamdera
import Parser exposing ((|.), (|=), chompWhile, getChompedString, oneOf, succeed, symbol)
import Types exposing (FrontendMsg, ToBackend(..))
import Url exposing (Url)


type DocUrl
    = DocUrl String
    | HomePage String
    | NoDocUrl


handleDocId : Url -> Command Command.FrontendOnly ToBackend FrontendMsg
handleDocId url =
    case parseDocUrl url of
        NoDocUrl ->
            Command.none

        HomePage str ->
            Effect.Lamdera.sendToBackend (GetHomePage str)

        DocUrl slug ->
            Effect.Lamdera.sendToBackend (SearchForDocumentsWithAuthorAndKey slug)



-- PARSE


parseDocUrl : Url -> DocUrl
parseDocUrl url =
    case Parser.run docUrlParser url.path of
        Ok docUrl ->
            docUrl

        Err _ ->
            NoDocUrl


docUrlParser : Parser.Parser DocUrl
docUrlParser =
    oneOf [ parseHomePage, docUrlUParser_ ]


docUrlUParser_ : Parser.Parser DocUrl
docUrlUParser_ =
    succeed (\k -> DocUrl k)
        |. symbol "/"
        |= oneOf [ uuidParser ]


uuidParser : Parser.Parser String
uuidParser =
    succeed identity
        |. symbol "uuid:"
        |= parseUuid



--


parseUuid : Parser.Parser String
parseUuid =
    getChompedString <|
        chompWhile (\c -> Char.isAlphaNum c || c == '-')


parseAlphaNum : Parser.Parser String
parseAlphaNum =
    getChompedString <|
        chompWhile (\c -> Char.isAlphaNum c)


parseHomePage : Parser.Parser DocUrl
parseHomePage =
    succeed HomePage
        |. symbol "/h/"
        |= parseAlphaNum
