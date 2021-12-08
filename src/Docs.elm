module Docs exposing (deleted, docsNotFound, notSignedIn)

import Document exposing (Document, empty)


notSignedIn : Document
notSignedIn =
    { empty
        | content = welcomeText
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
[!title](Document deleted)

Your document has been deleted.

![image](data:image/jpeg;base64,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)

"""


welcomeText =
    """

\\title{Welcome to Zipdocs}


\\italic{Use Zipdocs to effortlessly create documents in Markdown or MiniLaTeX.  A hassle-free, no-setup way to share short notes and articles, problem sets,
 etc. Support for mathematical notation and images.  Export your work to LaTeX, or generate a PDF file.}

$$
  \\int_0^1 x^n dx = \\frac{1}{n+1}
$$

\\strong{Login.} Not needed.  Just choose your language, click on \\strong{New}, and start writing.  But if you would like to
set up an account, just enter your username and password in the header and click on \\strong{Sign in | Sign up}.  With
an account, you have a searchable list of all your
documents, and you don't have to keep track of document links.

When you click on \\strong{New} to make a new document, you will get two links, which you will find in the footer of this app. The  first is private;
use it to  edit your document in the future.  If you are using the no-login option, keep this link safe!
There is no way to recover it.  The second link is to share with colleagues and
friends.  With it anyone can read your document but not
edit it.

Documents are automatically saved as you edit.


More info: \\xlink{Getting the most out of Zipdocs}{kn886-dd906}  • \\xlink{About MiniLaTeX}{qw172-kk223}  •
\\xlink{About XMarkdown}{nr402-bm985}

\\image{https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQRF0zeCqrYUxEmZXRq_IdQtrqlYyAWZ627og&usqp=CAU}
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
