module Evergreen.V409.Compiler.DifferentialParser exposing (..)

import Evergreen.V409.Compiler.AbstractDifferentialParser
import Evergreen.V409.Compiler.Acc
import Evergreen.V409.Parser.Block
import Evergreen.V409.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V409.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V409.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V409.Parser.Block.ExpressionBlock) Evergreen.V409.Compiler.Acc.Accumulator
