module Evergreen.V505.Compiler.DifferentialParser exposing (..)

import Evergreen.V505.Compiler.AbstractDifferentialParser
import Evergreen.V505.Compiler.Acc
import Evergreen.V505.Parser.Block
import Evergreen.V505.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V505.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V505.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V505.Parser.Block.ExpressionBlock) Evergreen.V505.Compiler.Acc.Accumulator
