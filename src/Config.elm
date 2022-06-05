module Config exposing
    ( appName
    , automaticSignoutLimit
    , automaticSignoutNoticePeriod
    , backendTickSeconds
    , cheatSheetRenderedTextId
    , debounceSaveDocumentInterval
    , defaultUrl
    , documentDeletedNotice
    , editSafetyInterval
    , fontWidth
    , frontendTickSeconds
    , helpDocumentId
    , host
    , indentationQuantum
    , initialLanguage
    , l0CheatsheetId
    , l0ManualId
    , loadingId
    , loadingText
    , masterDocLoadedPageId
    , maxDocSearchLimit
    , microLaTeXCheatsheetId
    , microLaTeXManualId
    , notFoundDocId
    , pdfServer
    , plainTextCheatsheetId
    , publicDocumentStartupSearchKey
    , renderedTextId
    , signOutDocumentId
    , startupHelpDocumentId
    , titleSize
    , transitKey
    , welcomeDocId
    , xmarkdownCheatsheetId
    )

import Env
import Parser.Language
import Url


fontWidth : Int
fontWidth =
    10


{-| Now set at 3 seconds, up from 0.3 seconds before
-}
debounceSaveDocumentInterval : Float
debounceSaveDocumentInterval =
    300


editSafetyInterval : Int
editSafetyInterval =
    5



-- seconds


l0ManualId =
    case Env.mode of
        Env.Production ->
            "id-62cdc3d3-b6d5-4f4d-b314-3f50f7a6aaef"

        Env.Development ->
            "id-d09b4fe1-e862-4f51-a94c-5744abda00db"


microLaTeXManualId =
    case Env.mode of
        Env.Production ->
            "id-4bc4ae5a-ce08-42ad-9e90-59eb381eba6f"

        Env.Development ->
            "id-be64f3c5-2765-44b3-9eed-f668f60a1594"


welcomeDocId =
    case Env.mode of
        Env.Production ->
            "id-gv236-po313"

        Env.Development ->
            "id-fa167-yd715"


frontendTickSeconds =
    case Env.mode of
        Env.Production ->
            1

        Env.Development ->
            1


backendTickSeconds =
    case Env.mode of
        Env.Production ->
            10

        Env.Development ->
            3


{-| Units = seconds
-}
automaticSignoutLimit =
    case Env.mode of
        Env.Production ->
            -- one hour
            3600

        Env.Development ->
            3600


{-| Units = seconds
-}
automaticSignoutNoticePeriod =
    case Env.mode of
        Env.Production ->
            -- 5 minutes
            300

        Env.Development ->
            300


maxDocSearchLimit =
    100


publicDocumentStartupSearchKey =
    "system:startup"


notFoundDocId =
    case Env.mode of
        Env.Production ->
            "id-sr565-tf824"

        Env.Development ->
            "id-fl180-br848"


l0CheatsheetId =
    case Env.mode of
        Env.Production ->
            "id-ef3f252c-3a9d-4944-9ff4-917ea77569f7"

        Env.Development ->
            "id-4262d505-50db-4a7f-8243-42f10344a45e"


microLaTeXCheatsheetId =
    case Env.mode of
        Env.Production ->
            "id-vv682-nv513"

        Env.Development ->
            "--"


xmarkdownCheatsheetId =
    case Env.mode of
        Env.Production ->
            "id-nv791-ih252"

        Env.Development ->
            "--"


signOutDocumentId =
    case Env.mode of
        Env.Production ->
            "id-aeeace09-a1eb-4ac2-956b-bb66ac072b95"

        Env.Development ->
            "id-93c08863-e803-44c3-a776-2df2ef067e3b"


plainTextCheatsheetId =
    case Env.mode of
        Env.Production ->
            "id-cm181-zs282"

        Env.Development ->
            "--"


loadingId =
    "id-gv197-mh043"


masterDocLoadedPageId =
    "id-vt202-ux358"


cheatSheetRenderedTextId =
    "__CHEATSHEET_RENDERED_TEXT__"


renderedTextId =
    "__RENDERED_TEXT__"


documentDeletedNotice =
    "id-dj146-un326"


appName =
    "Scripta.io"


host =
    case Env.mode of
        Env.Production ->
            "https://scripta.io"

        Env.Development ->
            "localhost/8000"


defaultUrl : Maybe Url.Url
defaultUrl =
    Url.fromString host


pdfServer =
    case Env.mode of
        Env.Production ->
            "https://pdfserv.app"

        Env.Development ->
            "https://pdfserv.app"


startupHelpDocumentId =
    "kc154.dg274"


helpDocumentId =
    "yr248.qb459"


transitKey =
    "1f0d8b16-9689-4310-829d-794a86abep1F"


initialLanguage =
    Parser.Language.MicroLaTeXLang


titleSize =
    32


indentationQuantum =
    2


loadingText =
    """
| title
Welcome to Scripta.io!

[tags startup]

[b [large What it is]]

[i Scripta is an interactive editing and publishing environment for]

| item
MicroLaTeX, a  variant of LaTeX


| item
L0, a markup language with a Lisp-like syntax


| item
XMarkdown, like Markdown, can render math

For more information:
[ilink Scripta id-jo518-lf384] |
[ilink  microLaTeX id-hq485-at830] |
[ilink L0 id-ag397-qq261] |
[ilink XMarkdown id-ud129-ab345]

[b [large Features]]

| item
No setup.  Just click [b New] and start typing.

| item
Text is rendered as you type

| item
Make pages that link to other pages — good for class notes,   home page, etc. [ilink (Some class notes) id-ab140-ke696],
[ilink (A home page)  id-wt972-vi327]

| item
Export to standard LaTeX and PDF

[image https://news.wttw.com/sites/default/files/styles/full/public/field/image/CardinalSnowtlparadisPixabayCrop.jpg?itok=iyp0zGMz]



[b [large Technical Info]]

Scripta.io is written in [link Elm https://elm-lang.org] using
the [link Lamdera framework https://dashboard.lamdera.app/],
so that both the frontend and backend run on Elm. For
the editor we use [link Codemirror 6 https://codemirror.net/6/] and for rendering of mathematical formulas, we use
[link KaTeX https://katex.org].

The Scripta codebase weighs in at about 10K lines of code,
two-thirds of which is the text-to-html compiler.
The [ilink Scripta compiler id-hx574-zz554] maps source
text in any one of the three designated markup languages to
a language-independent syntax tree.

The compiler has fairly good error-handling characteristics.
Syntax errors are discreetly noted in the rendered text in
real time;  the text below a block which has an error is rendered
normally.

The compiler will be released as open source software as soon as
it stops changing so quickly.

[b [large Acknowlegements]]

I would like to acknowledge and thank the many people from whom I
have learned and who have shared their knowledge and insight
with me over the course of the developing Scripta.  In roughly
chronological order: Evan Czaplicki, Ilias van Peer, Mario Rogic,
Nicholas Yang, Matt Griffith, and Rob Simmons and team at Brilliant.org.

[b [large Contact]]

  jxxcarlson at Google's email service.




"""
