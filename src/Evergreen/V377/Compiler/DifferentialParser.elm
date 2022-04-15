module Evergreen.V377.Compiler.DifferentialParser exposing (..)

import Evergreen.V377.Compiler.AbstractDifferentialParser
import Evergreen.V377.Compiler.Acc
import Evergreen.V377.Parser.Block
import Evergreen.V377.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V377.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V377.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V377.Parser.Block.ExpressionBlock) Evergreen.V377.Compiler.Acc.Accumulator
