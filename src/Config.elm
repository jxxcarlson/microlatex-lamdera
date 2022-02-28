module Config exposing
    ( appName
    , appUrl
    , documentDeletedNotice
    , helpDocumentId
    , initialLanguage
    , pdfServer
    , startupHelpDocumentId
    , transitKey
    , welcomeDocId
    )

import Parser.Language


welcomeDocId =
    -- "id-kl117-ej494"
    "id-xk211-qw247"


documentDeletedNotice =
    "id-ux175-hv037"


appName =
    "MicroLaTeX"


appUrl =
    -- "localhost/8000"
    "https://microlatex.lamdera.app"


pdfServer =
    "https://pdfserv.app"


startupHelpDocumentId =
    "kc154.dg274"


helpDocumentId =
    "yr248.qb459"


transitKey =
    "1f0d8b16-9689-4310-829d-794a86abep1F"


initialLanguage =
    Parser.Language.MicroLaTeXLang
