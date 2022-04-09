module Evergreen.V304.Compiler.DifferentialParser exposing (..)

import Evergreen.V304.Compiler.AbstractDifferentialParser
import Evergreen.V304.Compiler.Acc
import Evergreen.V304.Parser.Block
import Evergreen.V304.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V304.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V304.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V304.Parser.Block.ExpressionBlock) Evergreen.V304.Compiler.Acc.Accumulator
