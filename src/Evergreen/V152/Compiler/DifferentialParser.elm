module Evergreen.V152.Compiler.DifferentialParser exposing (..)

import Evergreen.V152.Compiler.AbstractDifferentialParser
import Evergreen.V152.Compiler.Acc
import Evergreen.V152.Parser.Block
import Evergreen.V152.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V152.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V152.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V152.Parser.Block.ExpressionBlock) Evergreen.V152.Compiler.Acc.Accumulator
