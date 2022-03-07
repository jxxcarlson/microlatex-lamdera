module Evergreen.V81.Compiler.DifferentialParser exposing (..)

import Evergreen.V81.Compiler.AbstractDifferentialParser
import Evergreen.V81.Compiler.Acc
import Evergreen.V81.Parser.Block
import Evergreen.V81.Parser.Expr
import Tree


type alias EditRecord =
    Evergreen.V81.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V81.Parser.Block.IntermediateBlock) (Tree.Tree (Evergreen.V81.Parser.Block.ExpressionBlock Evergreen.V81.Parser.Expr.Expr)) Evergreen.V81.Compiler.Acc.Accumulator
