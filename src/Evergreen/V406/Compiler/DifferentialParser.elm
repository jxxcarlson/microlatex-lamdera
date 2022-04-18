module Evergreen.V406.Compiler.DifferentialParser exposing (..)

import Evergreen.V406.Compiler.AbstractDifferentialParser
import Evergreen.V406.Compiler.Acc
import Evergreen.V406.Parser.Block
import Evergreen.V406.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V406.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V406.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V406.Parser.Block.ExpressionBlock) Evergreen.V406.Compiler.Acc.Accumulator
