module Evergreen.V269.Compiler.DifferentialParser exposing (..)

import Evergreen.V269.Compiler.AbstractDifferentialParser
import Evergreen.V269.Compiler.Acc
import Evergreen.V269.Parser.Block
import Evergreen.V269.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V269.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V269.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V269.Parser.Block.ExpressionBlock) Evergreen.V269.Compiler.Acc.Accumulator
