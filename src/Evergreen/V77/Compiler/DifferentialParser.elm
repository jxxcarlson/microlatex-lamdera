module Evergreen.V77.Compiler.DifferentialParser exposing (..)

import Evergreen.V77.Compiler.AbstractDifferentialParser
import Evergreen.V77.Compiler.Acc
import Evergreen.V77.Parser.Block
import Evergreen.V77.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V77.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V77.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V77.Parser.Block.ExpressionBlock Evergreen.V77.Parser.Expr.Expr)) Evergreen.V77.Compiler.Acc.Accumulator
