module Evergreen.V684.Compiler.DifferentialParser exposing (..)

import Evergreen.V684.Compiler.AbstractDifferentialParser
import Evergreen.V684.Compiler.Acc
import Evergreen.V684.Parser.Block
import Evergreen.V684.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V684.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V684.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V684.Parser.Block.ExpressionBlock) Evergreen.V684.Compiler.Acc.Accumulator
