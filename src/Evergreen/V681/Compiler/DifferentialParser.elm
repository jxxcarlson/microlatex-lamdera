module Evergreen.V681.Compiler.DifferentialParser exposing (..)

import Evergreen.V681.Compiler.AbstractDifferentialParser
import Evergreen.V681.Compiler.Acc
import Evergreen.V681.Parser.Block
import Evergreen.V681.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V681.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V681.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V681.Parser.Block.ExpressionBlock) Evergreen.V681.Compiler.Acc.Accumulator
