module Evergreen.V683.Compiler.DifferentialParser exposing (..)

import Evergreen.V683.Compiler.AbstractDifferentialParser
import Evergreen.V683.Compiler.Acc
import Evergreen.V683.Parser.Block
import Evergreen.V683.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V683.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V683.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V683.Parser.Block.ExpressionBlock) Evergreen.V683.Compiler.Acc.Accumulator
