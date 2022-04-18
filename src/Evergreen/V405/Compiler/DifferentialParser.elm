module Evergreen.V405.Compiler.DifferentialParser exposing (..)

import Evergreen.V405.Compiler.AbstractDifferentialParser
import Evergreen.V405.Compiler.Acc
import Evergreen.V405.Parser.Block
import Evergreen.V405.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V405.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V405.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V405.Parser.Block.ExpressionBlock) Evergreen.V405.Compiler.Acc.Accumulator
