module Evergreen.V710.Compiler.DifferentialParser exposing (..)

import Evergreen.V710.Compiler.AbstractDifferentialParser
import Evergreen.V710.Compiler.Acc
import Evergreen.V710.Parser.Block
import Evergreen.V710.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V710.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V710.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V710.Parser.Block.ExpressionBlock) Evergreen.V710.Compiler.Acc.Accumulator
