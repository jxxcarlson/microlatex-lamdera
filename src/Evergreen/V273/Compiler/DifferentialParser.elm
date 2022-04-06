module Evergreen.V273.Compiler.DifferentialParser exposing (..)

import Evergreen.V273.Compiler.AbstractDifferentialParser
import Evergreen.V273.Compiler.Acc
import Evergreen.V273.Parser.Block
import Evergreen.V273.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V273.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V273.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V273.Parser.Block.ExpressionBlock) Evergreen.V273.Compiler.Acc.Accumulator
