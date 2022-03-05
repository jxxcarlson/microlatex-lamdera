module Evergreen.V72.Compiler.DifferentialParser exposing (..)

import Evergreen.V72.Compiler.AbstractDifferentialParser
import Evergreen.V72.Compiler.Acc
import Evergreen.V72.Parser.Block
import Evergreen.V72.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V72.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V72.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V72.Parser.Block.ExpressionBlock Evergreen.V72.Parser.Expr.Expr)) Evergreen.V72.Compiler.Acc.Accumulator
