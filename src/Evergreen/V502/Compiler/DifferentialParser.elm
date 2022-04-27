module Evergreen.V502.Compiler.DifferentialParser exposing (..)

import Evergreen.V502.Compiler.AbstractDifferentialParser
import Evergreen.V502.Compiler.Acc
import Evergreen.V502.Parser.Block
import Evergreen.V502.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V502.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V502.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V502.Parser.Block.ExpressionBlock) Evergreen.V502.Compiler.Acc.Accumulator
