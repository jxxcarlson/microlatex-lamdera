module Evergreen.V41.Compiler.DifferentialParser exposing (..)

import Evergreen.V41.Compiler.AbstractDifferentialParser
import Evergreen.V41.Compiler.Acc
import Evergreen.V41.Parser.Block
import Evergreen.V41.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V41.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V41.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V41.Parser.Block.ExpressionBlock Evergreen.V41.Parser.Expr.Expr)) Evergreen.V41.Compiler.Acc.Accumulator
