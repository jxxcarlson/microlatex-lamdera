module Evergreen.V376.Compiler.DifferentialParser exposing (..)

import Evergreen.V376.Compiler.AbstractDifferentialParser
import Evergreen.V376.Compiler.Acc
import Evergreen.V376.Parser.Block
import Evergreen.V376.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V376.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V376.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V376.Parser.Block.ExpressionBlock) Evergreen.V376.Compiler.Acc.Accumulator
