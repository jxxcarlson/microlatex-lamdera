module Evergreen.V31.Compiler.DifferentialParser exposing (..)

import Evergreen.V31.Compiler.AbstractDifferentialParser
import Evergreen.V31.Compiler.Acc
import Evergreen.V31.Parser.Block
import Evergreen.V31.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V31.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V31.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V31.Parser.Block.ExpressionBlock Evergreen.V31.Parser.Expr.Expr)) Evergreen.V31.Compiler.Acc.Accumulator
