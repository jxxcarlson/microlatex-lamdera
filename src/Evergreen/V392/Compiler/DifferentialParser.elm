module Evergreen.V392.Compiler.DifferentialParser exposing (..)

import Evergreen.V392.Compiler.AbstractDifferentialParser
import Evergreen.V392.Compiler.Acc
import Evergreen.V392.Parser.Block
import Evergreen.V392.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V392.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V392.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V392.Parser.Block.ExpressionBlock) Evergreen.V392.Compiler.Acc.Accumulator
