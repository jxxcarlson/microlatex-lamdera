module Evergreen.V631.Compiler.DifferentialParser exposing (..)

import Evergreen.V631.Compiler.AbstractDifferentialParser
import Evergreen.V631.Compiler.Acc
import Evergreen.V631.Parser.Block
import Evergreen.V631.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V631.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V631.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V631.Parser.Block.ExpressionBlock) Evergreen.V631.Compiler.Acc.Accumulator
