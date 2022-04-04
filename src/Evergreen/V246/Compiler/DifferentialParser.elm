module Evergreen.V246.Compiler.DifferentialParser exposing (..)

import Evergreen.V246.Compiler.AbstractDifferentialParser
import Evergreen.V246.Compiler.Acc
import Evergreen.V246.Parser.Block
import Evergreen.V246.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V246.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V246.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V246.Parser.Block.ExpressionBlock) Evergreen.V246.Compiler.Acc.Accumulator
