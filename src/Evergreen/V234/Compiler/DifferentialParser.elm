module Evergreen.V234.Compiler.DifferentialParser exposing (..)

import Evergreen.V234.Compiler.AbstractDifferentialParser
import Evergreen.V234.Compiler.Acc
import Evergreen.V234.Parser.Block
import Evergreen.V234.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V234.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V234.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V234.Parser.Block.ExpressionBlock) Evergreen.V234.Compiler.Acc.Accumulator
