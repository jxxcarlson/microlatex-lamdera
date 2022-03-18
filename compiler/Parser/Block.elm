module Parser.Block exposing
    ( BlockType(..), ExpressionBlock(..), IntermediateBlock(..)
    , RawBlock, getArgs, getBlockType, getContent, getName
    )

{-| Source text is parsed into a tree of IntermediateBlocks, where the tree
structure is determined by the indentation level. The expression parser
is mapped over this tree, yielding a tree of ExpressionBlocks. The renderer
consumes trees of ExpressionBlocks to produce Html.

  - The two blocks differ only in their content and children fields.

  - Blocks contain auxiliary information used by editors and IDE's, e.g.,
    the line number in the source text at which the text of the block begins.

@docs BlockType, ExpressionBlock, IntermediateBlock

-}

import Either exposing (Either)
import Parser.Expr exposing (Expr)


type alias RawBlock =
    { indent : Int
    , lineNumber : Int
    , numberOfLines : Int
    , content : String
    }


{-| -}
type IntermediateBlock
    = IntermediateBlock
        { name : Maybe String
        , args : List String
        , indent : Int
        , lineNumber : Int
        , numberOfLines : Int
        , id : String
        , tag : String
        , blockType : BlockType
        , content : List String
        , messages : List String
        , sourceText : String
        }


getName : IntermediateBlock -> Maybe String
getName (IntermediateBlock { name }) =
    name


getArgs : IntermediateBlock -> List String
getArgs (IntermediateBlock { args }) =
    args


getContent : IntermediateBlock -> List String
getContent (IntermediateBlock { content }) =
    content


getBlockType : IntermediateBlock -> BlockType
getBlockType (IntermediateBlock { blockType }) =
    blockType


{-| -}
type ExpressionBlock
    = ExpressionBlock
        { name : Maybe String
        , args : List String
        , indent : Int
        , lineNumber : Int
        , numberOfLines : Int
        , id : String
        , tag : String
        , blockType : BlockType
        , content : Either String (List Expr)
        , messages : List String
        , sourceText : String
        }


{-| An ordinary block has the form

    | BLOCK-HEADER
    BODY

Examples:

    | heading 1
    Introduction

    | theorem
    There are infinitely many primes $p \equiv 1\ mod\ 4$.

Verbatim blocks have the form

    || BLOCK-HEADER
    BODY

Examples:

    || equation
    \int_0^1 x^n dx = \frac{1}{n+1}

Paragraphs are "anonymous" blocks.

-}
type BlockType
    = Paragraph
    | OrdinaryBlock (List String)
    | VerbatimBlock (List String)
