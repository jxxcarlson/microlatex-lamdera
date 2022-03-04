module Evergreen.V59.Compiler.DifferentialParser exposing (..)

import Evergreen.V59.Compiler.AbstractDifferentialParser
import Evergreen.V59.Compiler.Acc
import Evergreen.V59.Parser.Block
import Evergreen.V59.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V59.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V59.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V59.Parser.Block.ExpressionBlock Evergreen.V59.Parser.Expr.Expr)) Evergreen.V59.Compiler.Acc.Accumulator
