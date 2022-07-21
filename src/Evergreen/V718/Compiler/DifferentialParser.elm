module Evergreen.V718.Compiler.DifferentialParser exposing (..)

import Evergreen.V718.Compiler.AbstractDifferentialParser
import Evergreen.V718.Compiler.Acc
import Evergreen.V718.Parser.Block
import Evergreen.V718.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V718.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V718.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V718.Parser.Block.ExpressionBlock) Evergreen.V718.Compiler.Acc.Accumulator
