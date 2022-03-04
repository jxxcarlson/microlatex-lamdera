module Evergreen.V55.Compiler.DifferentialParser exposing (..)

import Evergreen.V55.Compiler.AbstractDifferentialParser
import Evergreen.V55.Compiler.Acc
import Evergreen.V55.Parser.Block
import Evergreen.V55.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V55.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V55.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V55.Parser.Block.ExpressionBlock Evergreen.V55.Parser.Expr.Expr)) Evergreen.V55.Compiler.Acc.Accumulator
