module Evergreen.V359.Compiler.DifferentialParser exposing (..)

import Evergreen.V359.Compiler.AbstractDifferentialParser
import Evergreen.V359.Compiler.Acc
import Evergreen.V359.Parser.Block
import Evergreen.V359.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V359.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V359.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V359.Parser.Block.ExpressionBlock) Evergreen.V359.Compiler.Acc.Accumulator
