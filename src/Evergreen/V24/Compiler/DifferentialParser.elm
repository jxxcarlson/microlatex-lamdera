module Evergreen.V24.Compiler.DifferentialParser exposing (..)

import Evergreen.V24.Compiler.AbstractDifferentialParser
import Evergreen.V24.Compiler.Acc
import Evergreen.V24.Parser.Block
import Evergreen.V24.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V24.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V24.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V24.Parser.Block.ExpressionBlock Evergreen.V24.Parser.Expr.Expr)) Evergreen.V24.Compiler.Acc.Accumulator
