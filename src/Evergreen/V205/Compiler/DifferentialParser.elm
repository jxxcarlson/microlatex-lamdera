module Evergreen.V205.Compiler.DifferentialParser exposing (..)

import Evergreen.V205.Compiler.AbstractDifferentialParser
import Evergreen.V205.Compiler.Acc
import Evergreen.V205.Parser.Block
import Evergreen.V205.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V205.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V205.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V205.Parser.Block.ExpressionBlock) Evergreen.V205.Compiler.Acc.Accumulator
