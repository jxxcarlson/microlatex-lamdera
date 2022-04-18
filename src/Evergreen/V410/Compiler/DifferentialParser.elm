module Evergreen.V410.Compiler.DifferentialParser exposing (..)

import Evergreen.V410.Compiler.AbstractDifferentialParser
import Evergreen.V410.Compiler.Acc
import Evergreen.V410.Parser.Block
import Evergreen.V410.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V410.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V410.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V410.Parser.Block.ExpressionBlock) Evergreen.V410.Compiler.Acc.Accumulator
