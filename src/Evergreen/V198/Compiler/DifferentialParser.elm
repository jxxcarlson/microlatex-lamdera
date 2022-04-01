module Evergreen.V198.Compiler.DifferentialParser exposing (..)

import Evergreen.V198.Compiler.AbstractDifferentialParser
import Evergreen.V198.Compiler.Acc
import Evergreen.V198.Parser.Block
import Evergreen.V198.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V198.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V198.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V198.Parser.Block.ExpressionBlock) Evergreen.V198.Compiler.Acc.Accumulator
