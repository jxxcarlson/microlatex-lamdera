module Evergreen.V391.Compiler.DifferentialParser exposing (..)

import Evergreen.V391.Compiler.AbstractDifferentialParser
import Evergreen.V391.Compiler.Acc
import Evergreen.V391.Parser.Block
import Evergreen.V391.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V391.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V391.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V391.Parser.Block.ExpressionBlock) Evergreen.V391.Compiler.Acc.Accumulator
