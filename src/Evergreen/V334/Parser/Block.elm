module Evergreen.V334.Parser.Block exposing (..)

import Either
import Evergreen.V334.Parser.Expr


type BlockType
    = Paragraph
    | OrdinaryBlock (List String)
    | VerbatimBlock (List String)


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
        , content : Either.Either String (List Evergreen.V334.Parser.Expr.Expr)
        , messages : List String
        , sourceText : String
        }
