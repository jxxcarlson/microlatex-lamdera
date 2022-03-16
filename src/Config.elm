module Config exposing
    ( appName
    , appUrl
    , documentDeletedNotice
    , helpDocumentId
    , indentationQuantum
    , initialLanguage
    , loadingId
    , loadingText
    , masterDocLoadedPageId
    , pdfServer
    , startupHelpDocumentId
    , titleSize
    , transitKey
    , welcomeDocId
    )

import Parser.Language


welcomeDocId =
    "id-gv236-po313"


loadingId =
    "id-gv197-mh043"


masterDocLoadedPageId =
    "id-vt202-ux358\n"


loadingText1 =
    """
| title
Loading ...

[image https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS_2Dis9S-LNLx0xVNXKR9ox5Oj0Nv2-nqIGg&usqp=CAU]
"""


loadingText =
    """
| title
Welcome to Scripta!

[tags startup]

[i Scripta is an interactive editing and publishing environment for a small set of markup languages:]

| item
MicroLaTeX, a small variant of LaTeX
[ilink  — learn more id-to974-lt782]

| item
L0, a markup language with a Lisp-like syntax 
[ilink — learn more id-xe170-zc087]

| item
XMarkdown, a variant of Markdown, that can render math — coming March 30.

[image https://news.wttw.com/sites/default/files/styles/full/public/field/image/CardinalSnowtlparadisPixabayCrop.jpg?itok=iyp0zGMz]

[b [large Features]]

| item 
No setup.  Just click [b New] and start typing.

| item
Text is rendered as you type

| item
Make pages that link to other pages — good for class notes, a home page, etc.

| item
Export to standard LaTeX and PDF

"""



-- "id-kl117-ej494"
-- "id-gv236-po313"


documentDeletedNotice =
    "id-ux175-hv037"


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
