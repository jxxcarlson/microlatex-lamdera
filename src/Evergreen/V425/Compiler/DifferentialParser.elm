module Evergreen.V425.Compiler.DifferentialParser exposing (..)

import Evergreen.V425.Compiler.AbstractDifferentialParser
import Evergreen.V425.Compiler.Acc
import Evergreen.V425.Parser.Block
import Evergreen.V425.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V425.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V425.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V425.Parser.Block.ExpressionBlock) Evergreen.V425.Compiler.Acc.Accumulator
