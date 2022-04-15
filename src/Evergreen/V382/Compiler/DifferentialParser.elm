module Evergreen.V382.Compiler.DifferentialParser exposing (..)

import Evergreen.V382.Compiler.AbstractDifferentialParser
import Evergreen.V382.Compiler.Acc
import Evergreen.V382.Parser.Block
import Evergreen.V382.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V382.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V382.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V382.Parser.Block.ExpressionBlock) Evergreen.V382.Compiler.Acc.Accumulator
