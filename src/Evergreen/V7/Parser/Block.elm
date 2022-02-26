module Evergreen.V7.Parser.Block exposing (..)

import Either
import Evergreen.V7.Parser.Expr


type BlockType
    = Paragraph
    | OrdinaryBlock (List String)
    | VerbatimBlock (List String)


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
        , content : String
        , messages : List String
        , children : List IntermediateBlock
        , sourceText : String
        }


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
        , content : Either.Either String (List Evergreen.V7.Parser.Expr.Expr)
        , messages : List String
        , children : List ExpressionBlock
        , sourceText : String
        }
