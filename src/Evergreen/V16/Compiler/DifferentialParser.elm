module Evergreen.V16.Compiler.DifferentialParser exposing (..)

import Evergreen.V16.Compiler.AbstractDifferentialParser
import Evergreen.V16.Compiler.Acc
import Evergreen.V16.Parser.Block
import Evergreen.V16.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V16.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V16.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V16.Parser.Block.ExpressionBlock Evergreen.V16.Parser.Expr.Expr)) Evergreen.V16.Compiler.Acc.Accumulator
