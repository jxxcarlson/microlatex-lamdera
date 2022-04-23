module Evergreen.V476.Compiler.DifferentialParser exposing (..)

import Evergreen.V476.Compiler.AbstractDifferentialParser
import Evergreen.V476.Compiler.Acc
import Evergreen.V476.Parser.Block
import Evergreen.V476.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V476.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V476.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V476.Parser.Block.ExpressionBlock) Evergreen.V476.Compiler.Acc.Accumulator
