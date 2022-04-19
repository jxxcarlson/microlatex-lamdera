module Docs exposing (deleted, docsNotFound, notSignedIn, simpleWelcomeDoc)

import Document exposing (Document, empty)
import View.Data


notSignedIn : Document
notSignedIn =
    { empty
        | content = View.Data.welcome
        , id = "id-sys-1"
        , publicId = "public-sys-1"
    }


deleted : Document
deleted =
    { empty
        | content = deletedText
        , id = "id-sys-2"
        , publicId = "public-sys-2"
    }


deletedText =
    """
| title
Document deleted

Your document has been deleted.


"""


docsNotFound =
    { empty
        | content = docsNotFoundText
        , id = "id-sys-2"
        , publicId = "public-sys-2"
    }


docsNotFoundText =
    """
[title Oops!]

[i  Sorry, could not find your documents]

[i To create a document, press the [b New] button above, on left.]
"""


simpleWelcomeDoc =
    let
        emptyDoc =
            Document.empty
    in
    { emptyDoc | content = simpleWelcomeText, id = "simpleWelcomeDoc" }


simpleWelcomeText =
    """
| title
Welcome to Scripta.io!


[image https://news.wttw.com/sites/default/files/styles/full/public/field/image/CardinalSnowtlparadisPixabayCrop.jpg?itok=iyp0zGMz]
"""
