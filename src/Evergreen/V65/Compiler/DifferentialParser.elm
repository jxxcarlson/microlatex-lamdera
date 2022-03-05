module Evergreen.V65.Compiler.DifferentialParser exposing (..)

import Evergreen.V65.Compiler.AbstractDifferentialParser
import Evergreen.V65.Compiler.Acc
import Evergreen.V65.Parser.Block
import Evergreen.V65.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V65.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V65.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V65.Parser.Block.ExpressionBlock Evergreen.V65.Parser.Expr.Expr)) Evergreen.V65.Compiler.Acc.Accumulator
