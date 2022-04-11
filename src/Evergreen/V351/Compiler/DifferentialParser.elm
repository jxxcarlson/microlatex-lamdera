module Evergreen.V351.Compiler.DifferentialParser exposing (..)

import Evergreen.V351.Compiler.AbstractDifferentialParser
import Evergreen.V351.Compiler.Acc
import Evergreen.V351.Parser.Block
import Evergreen.V351.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V351.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V351.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V351.Parser.Block.ExpressionBlock) Evergreen.V351.Compiler.Acc.Accumulator
