module Evergreen.V316.Compiler.DifferentialParser exposing (..)

import Evergreen.V316.Compiler.AbstractDifferentialParser
import Evergreen.V316.Compiler.Acc
import Evergreen.V316.Parser.Block
import Evergreen.V316.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V316.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V316.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V316.Parser.Block.ExpressionBlock) Evergreen.V316.Compiler.Acc.Accumulator
