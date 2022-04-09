module Evergreen.V308.Compiler.DifferentialParser exposing (..)

import Evergreen.V308.Compiler.AbstractDifferentialParser
import Evergreen.V308.Compiler.Acc
import Evergreen.V308.Parser.Block
import Evergreen.V308.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V308.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V308.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V308.Parser.Block.ExpressionBlock) Evergreen.V308.Compiler.Acc.Accumulator
