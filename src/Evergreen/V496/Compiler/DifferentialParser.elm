module Evergreen.V496.Compiler.DifferentialParser exposing (..)

import Evergreen.V496.Compiler.AbstractDifferentialParser
import Evergreen.V496.Compiler.Acc
import Evergreen.V496.Parser.Block
import Evergreen.V496.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V496.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V496.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V496.Parser.Block.ExpressionBlock) Evergreen.V496.Compiler.Acc.Accumulator
