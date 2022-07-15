module Abstract exposing
    ( Abstract
    , AbstractOLD
    , empty
    , get
    , getBlockContents
    , getElement
    , getItem
    , getRawItem
    , str1
    , str2
    , str3
    , toString
    )

import Dict exposing (Dict)
import Document exposing (Document)
import Parser exposing ((|.), (|=), Parser)
import Parser.Language exposing (Language(..))


type alias Abstract =
    { title : String, author : String, abstract : String, tags : String, digest : String }


type alias AbstractOLD =
    { title : String, author : String, abstract : String, tags : String }


toString : Abstract -> String
toString a =
    [ a.title, a.author, a.tags ] |> String.join "; "


empty =
    { title = ""
    , author = ""
    , abstract = ""
    , tags = ""
    , digest = ""
    }


runParser stringParser str default =
    case Parser.run stringParser str of
        Ok s ->
            s

        Err _ ->
            default


getItem : Language -> String -> String -> String
getItem language key str =
    -- TODO: review this
    case language of
        -- TODO: deal with the XX's
        L0Lang ->
            getElement key str

        MicroLaTeXLang ->
            runParser (macroValParser key) str ("XX:" ++ key)

        PlainTextLang ->
            "XX:" ++ key

        XMarkdownLang ->
            "XX:" ++ key


getRawItem : Language -> String -> String -> Maybe String
getRawItem language key str =
    case language of
        L0Lang ->
            Parser.run (rawElementParser key) str |> Result.toMaybe

        MicroLaTeXLang ->
            Parser.run (rawMacroParser key) str |> Result.toMaybe

        PlainTextLang ->
            Nothing

        XMarkdownLang ->
            Parser.run (rawXMarkdownElementParser key) str |> Result.toMaybe


get : Maybe String -> Language -> String -> Abstract
get author_ lang source =
    -- TODO: review this
    let
        author =
            case author_ of
                Nothing ->
                    "((no-author))"

                Just realAuthor ->
                    realAuthor
    in
    case lang of
        L0Lang ->
            getForL0 author source

        MicroLaTeXLang ->
            getForMiniLaTeX author source

        PlainTextLang ->
            getForL0 author source

        XMarkdownLang ->
            getForL0 author source


getForL0 : String -> String -> Abstract
getForL0 author source =
    let
        title =
            getBlockContents "title" source

        subtitle =
            getBlockContents "subtitle" source

        abstract =
            getBlockContents "abstract" source

        tags =
            getElement "tags" source
    in
    { title = title
    , author = author
    , abstract = abstract
    , tags = tags
    , digest = [ title, subtitle, author, abstract, tags ] |> String.join " " |> String.toLower
    }


getForMiniLaTeX : String -> String -> Abstract
getForMiniLaTeX author source =
    let
        title =
            --getBlockContents "title" source
            runParser (macroValParser "title") source "title"

        subtitle =
            --getBlockContents "subtitle" source
            runParser (macroValParser "subtitle") source "subtitle"

        abstract =
            --getBlockContents "abstract" source
            runParser (macroValParser "abstract") source "abstract"

        tags =
            runParser (macroValParser "tags") source "abstract"
    in
    { title = title
    , author = author
    , abstract = abstract
    , tags = tags
    , digest = [ title, subtitle, author, abstract, tags ] |> String.join " " |> String.toLower
    }


getElement : String -> String -> String
getElement itemName source =
    case Parser.run (elementParser itemName) source of
        Err _ ->
            ""

        Ok str ->
            str


{-|

    > getBlockContents "title" "one\ntwo\n\n| title\nfoo bar\nbaz\n\n1\n2"
      "foo bar\nbaz"

-}
getBlockContents : String -> String -> String
getBlockContents blockName source =
    case Parser.run (blockParser blockName) source of
        Err _ ->
            ""

        Ok str ->
            str


{-|

    > getItem "title" "o [foo bar] ho ho ho [title Foo] blah blah"
    "Foo" : String

-}
elementParser : String -> Parser String
elementParser name =
    Parser.succeed String.slice
        |. Parser.chompUntil "["
        |. Parser.chompUntil name
        |. Parser.symbol name
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil "]"
        |= Parser.getOffset
        |= Parser.getSource


{-|

    > getItem "title" "o [foo bar] ho ho ho [title Foo] blah blah"
    "[title Foo]" : String

-}
rawElementParser : String -> Parser String
rawElementParser name =
    (Parser.succeed String.slice
        |. Parser.chompUntil "["
        |. Parser.chompUntil name
        |= Parser.getOffset
        |. Parser.symbol name
        |. Parser.spaces
        |. Parser.chompUntil "]"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map (\s -> "[" ++ s ++ "]")


rawXMarkdownElementParser : String -> Parser String
rawXMarkdownElementParser name =
    (Parser.succeed String.slice
        |. Parser.chompUntil "@["
        |. Parser.chompUntil name
        |= Parser.getOffset
        |. Parser.symbol name
        |. Parser.spaces
        |. Parser.chompUntil "]"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map (\s -> "[" ++ s ++ "]")


blockParser : String -> Parser String
blockParser name =
    (Parser.succeed String.slice
        |. Parser.chompUntil "| "
        |. Parser.chompUntil name
        |. Parser.symbol name
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil "\n"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map String.trim


{-|

    > run (rawElementParser "title") "o [tags foo, bar] ho ho ho [title    Foo] blah blah"
    Ok ("[title    Foo]")

-}
macroValParser : String -> Parser String
macroValParser macroName =
    (Parser.succeed String.slice
        |. Parser.chompUntil ("\\" ++ macroName ++ "{")
        |. Parser.symbol ("\\" ++ macroName ++ "{")
        |. Parser.spaces
        |= Parser.getOffset
        |. Parser.chompUntil "}"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map String.trim


{-|

    > run (rawMacroParser "tags") "foo bar\n\n \\title{abc} djfdkj \\tags{foo,    bar} djlfja;d"
    Ok ("\\tags{foo,    bar}")

-}
rawMacroParser : String -> Parser String
rawMacroParser macroName =
    (Parser.succeed String.slice
        |. Parser.chompUntil ("\\" ++ macroName ++ "{")
        |. Parser.symbol ("\\" ++ macroName ++ "{")
        |= Parser.getOffset
        |. Parser.spaces
        |. Parser.chompUntil "}"
        |= Parser.getOffset
        |= Parser.getSource
    )
        |> Parser.map (\s -> "\\" ++ macroName ++ "{" ++ s ++ "}")


str1 =
    """
This is a test


| title
Foo Bar



|| ho
ho


"""


str2 =
    """
| title
Foo Bar

aaa
"""


str3 =
    """
| title
Markup Description


| subtitle
My New Project (for Krakow)

| author
James Carlson

| abstract
This is about cool stuff

Markup is a simple markup language which we use  to illustrate an
approach to fault-tolerant parsing. Here is a short paragraph
in Markup:

```
Pythagoras says that for a [i right] triangle,
$a^2 + b^2 = c^2$, where the letters denote the
lengths of the altitude, base, and hypotenuse.
Pythagoras was [i [blue quite] the dude]!
```

In an expression like `[i right]`, the `i` stands for the
italicize function and `right` serves as an argument to it.
In the expression `[i [blue quite] the dude]`, "quite" is
rendered in italicized blue text while "the dude" is simply
italicized. Apart from special expressions like the ones used
for mathematical text and code,  Markup consists of ordinary text
and the Lisp-like expressions bounded  by brackets.


The idea behind the parser is to first transform the
source text into a list of tokens, then convert the list of
tokens into a list of expressions using
a kind of shift-reduce parser.  The shift-reduce parser is a
functional loop that operates on a value of type `State`, one
field of which is a stack of tokens:

|| code
type alias State =
    { tokens : List Token
    , numberOfTokens : Int
    , tokenIndex : Int
    , committed : List Expr
    , stack : List Token
    }

run : State -> State
run state =
    loop state nextStep


The `nextStep` function operates as follows

| item
Try to get the token at index `state.tokenIndex`; it will be either `Nothing` or `Just token`.

| item
If the return value is `Nothing`, examine the stack. If it is
empty, the loop is complete.  If it is nonempty,
the stack could not be  reduced.  This is an error, so we call `recoverFromError state`.

| item
If the return value is `Just token`, push the token onto the
stack or commit it immediately, depending on the nature of the
token and whether the stack is empty.  Then increment
`state.tokenIndex`, call `reduceStack` and then re-enter the
loop.

Below we describe the tokenizer, the parser, and error recovery. Very briefly, error recovery works by pattern matching on the reversed stack. The push or commit strategy guarantees that the stack begins with a left bracket token, a math token, or a code token. Then we proceed as follows:

| item
If the reversed stack begins with two left brackets, push an
error message onto `stack.committed`, set `state.tokenIndex` to
the token index of the second left bracket, clear the stack,
and re-run the parser on the truncated token list.

| item
If the reversed stack begins with a left bracket followed by a
text token which we take to be a function name, push an error
message onto `state.committed`, set `state.tokenIndex` to the
token index of the function name plus one, clear the stack, and
re-run the parser on the truncated token list.


| item
Etc: a few more patterns, e.g., for code and math.

In other words, when an error is encountered, we make note of the fact in `state.committed` and skip forward in the list of tokens in an attempt to recover from the error.  In this way two properties are guaranteed:


| item
A syntax tree is built based on the full text.

| item
Errors are signaled in the syntax tree and therefore in the rendered text.

| item
Text following an error is not messed up.


The last property is a consequence of the "greediness" of the recovery algorithm.




## Tokenizer

The tokenizer converts a string into a list of tokens, where


|| code
type Token
    = LB Meta
    | RB Meta
    | S String Meta
    | W String Meta
    | MathToken Meta
    | CodeToken Meta
    | TokenError (List (DeadEnd Context Problem)) Meta

type alias Meta =
    { begin : Int, end : Int, index: Int }


Here `LB` and `RB` stand for left and right-brackets;
`S` stands for string data, which in practice means "words" (no interior spaces)
and `W` stands for whitespace.  The string "$" generates a `MathToken`,
while a backtick generates a `CodeToken.`  Thus

|| code
> import Parser.Token exposing(..)
> run "[i foo] $x^2$" |> List.reverse
  [  LB        { begin = 0, end = 0, index = 0   }
   , S "i"     { begin = 1, end = 1, index = 1   }
   , W (" ")   { begin = 2, end = 2, index = 2   }
   , S "foo".  { begin = 3, end = 5, index = 3   }
   , RB        { begin = 6, end = 6, index = 4   }
   , W (" ")   { begin = 7, end = 7, index = 5   }
   , MathToken { begin = 8, end = 8, index = 6   }
   , S "x^2"   { begin = 9, end = 11, index = 7  }
   , MathToken { begin = 12, end = 12, index = 8 }
 ]



The `Meta` components locates
the substring tokenized in the source text and also carries
an index which locates
a given token in a list of tokens.

The `Token.run` function has a companion which gives less
verbose output:
"""
