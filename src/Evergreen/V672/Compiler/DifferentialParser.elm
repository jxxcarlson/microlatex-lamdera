module Evergreen.V672.Compiler.DifferentialParser exposing (..)

import Evergreen.V672.Compiler.AbstractDifferentialParser
import Evergreen.V672.Compiler.Acc
import Evergreen.V672.Parser.Block
import Evergreen.V672.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V672.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V672.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V672.Parser.Block.ExpressionBlock) Evergreen.V672.Compiler.Acc.Accumulator
