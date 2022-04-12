module Evergreen.V360.Compiler.DifferentialParser exposing (..)

import Evergreen.V360.Compiler.AbstractDifferentialParser
import Evergreen.V360.Compiler.Acc
import Evergreen.V360.Parser.Block
import Evergreen.V360.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V360.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V360.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V360.Parser.Block.ExpressionBlock) Evergreen.V360.Compiler.Acc.Accumulator
