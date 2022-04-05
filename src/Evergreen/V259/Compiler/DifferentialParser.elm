module Evergreen.V259.Compiler.DifferentialParser exposing (..)

import Evergreen.V259.Compiler.AbstractDifferentialParser
import Evergreen.V259.Compiler.Acc
import Evergreen.V259.Parser.Block
import Evergreen.V259.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V259.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V259.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V259.Parser.Block.ExpressionBlock) Evergreen.V259.Compiler.Acc.Accumulator
