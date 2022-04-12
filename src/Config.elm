module Config exposing
    ( appName
    , appUrl
    , backendTickSeconds
    , documentDeletedNotice
    , frontendTickSeconds
    , helpDocumentId
    , indentationQuantum
    , initialLanguage
    , l0CheetsheetId
    , loadingId
    , loadingText
    , masterDocLoadedPageId
    , maxDocSearchLimit
    , pdfServer
    , publicDocumentStartupSearchKey
    , startupHelpDocumentId
    , titleSize
    , transitKey
    , welcomeDocId
    )

import Env
import Parser.Language


welcomeDocId =
    case Env.mode of
        Env.Production ->
            "id-gv236-po313"

        Env.Development ->
            "id-da833-rp359"


frontendTickSeconds =
    case Env.mode of
        Env.Production ->
            1

        Env.Development ->
            5


backendTickSeconds =
    case Env.mode of
        Env.Production ->
            30

        Env.Development ->
            30


maxDocSearchLimit =
    30


publicDocumentStartupSearchKey =
    "system:startup"


l0CheetsheetId =
    case Env.mode of
        Env.Production ->
            "id-go206-ak343"

        Env.Development ->
            "id-pu157-zz849"


loadingId =
    "id-gv197-mh043"


masterDocLoadedPageId =
    "id-vt202-ux358"


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



-- "id-kl117-ej494"
-- "id-gv236-po313"


documentDeletedNotice =
    "id-dj146-un326"


appName =
    "Scripta.io"


appUrl =
    -- "localhost/8000"
    "https://microlatex.lamdera.app"


pdfServer =
    "https://pdfserv.app"


startupHelpDocumentId =
    "kc154.dg274"



-- id-xk211-qw247


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
