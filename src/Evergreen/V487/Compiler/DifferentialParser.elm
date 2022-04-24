module Evergreen.V487.Compiler.DifferentialParser exposing (..)

import Evergreen.V487.Compiler.AbstractDifferentialParser
import Evergreen.V487.Compiler.Acc
import Evergreen.V487.Parser.Block
import Evergreen.V487.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V487.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V487.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V487.Parser.Block.ExpressionBlock) Evergreen.V487.Compiler.Acc.Accumulator
