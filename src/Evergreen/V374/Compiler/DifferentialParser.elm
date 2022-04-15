module Evergreen.V374.Compiler.DifferentialParser exposing (..)

import Evergreen.V374.Compiler.AbstractDifferentialParser
import Evergreen.V374.Compiler.Acc
import Evergreen.V374.Parser.Block
import Evergreen.V374.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V374.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V374.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V374.Parser.Block.ExpressionBlock) Evergreen.V374.Compiler.Acc.Accumulator
