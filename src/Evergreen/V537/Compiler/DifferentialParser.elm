module Evergreen.V537.Compiler.DifferentialParser exposing (..)

import Evergreen.V537.Compiler.AbstractDifferentialParser
import Evergreen.V537.Compiler.Acc
import Evergreen.V537.Parser.Block
import Evergreen.V537.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V537.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V537.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V537.Parser.Block.ExpressionBlock) Evergreen.V537.Compiler.Acc.Accumulator
