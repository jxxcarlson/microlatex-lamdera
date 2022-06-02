module Evergreen.V546.Compiler.DifferentialParser exposing (..)

import Evergreen.V546.Compiler.AbstractDifferentialParser
import Evergreen.V546.Compiler.Acc
import Evergreen.V546.Parser.Block
import Evergreen.V546.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V546.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V546.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V546.Parser.Block.ExpressionBlock) Evergreen.V546.Compiler.Acc.Accumulator
