module Evergreen.V337.Compiler.DifferentialParser exposing (..)

import Evergreen.V337.Compiler.AbstractDifferentialParser
import Evergreen.V337.Compiler.Acc
import Evergreen.V337.Parser.Block
import Evergreen.V337.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V337.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V337.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V337.Parser.Block.ExpressionBlock) Evergreen.V337.Compiler.Acc.Accumulator
