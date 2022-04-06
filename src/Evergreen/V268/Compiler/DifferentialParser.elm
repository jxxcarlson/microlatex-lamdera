module Evergreen.V268.Compiler.DifferentialParser exposing (..)

import Evergreen.V268.Compiler.AbstractDifferentialParser
import Evergreen.V268.Compiler.Acc
import Evergreen.V268.Parser.Block
import Evergreen.V268.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V268.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V268.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V268.Parser.Block.ExpressionBlock) Evergreen.V268.Compiler.Acc.Accumulator
