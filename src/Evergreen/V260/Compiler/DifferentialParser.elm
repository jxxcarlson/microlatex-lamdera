module Evergreen.V260.Compiler.DifferentialParser exposing (..)

import Evergreen.V260.Compiler.AbstractDifferentialParser
import Evergreen.V260.Compiler.Acc
import Evergreen.V260.Parser.Block
import Evergreen.V260.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V260.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V260.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V260.Parser.Block.ExpressionBlock) Evergreen.V260.Compiler.Acc.Accumulator
