module Evergreen.V494.Compiler.DifferentialParser exposing (..)

import Evergreen.V494.Compiler.AbstractDifferentialParser
import Evergreen.V494.Compiler.Acc
import Evergreen.V494.Parser.Block
import Evergreen.V494.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V494.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V494.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V494.Parser.Block.ExpressionBlock) Evergreen.V494.Compiler.Acc.Accumulator
