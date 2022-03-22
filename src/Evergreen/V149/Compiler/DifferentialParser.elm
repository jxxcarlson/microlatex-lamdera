module Evergreen.V149.Compiler.DifferentialParser exposing (..)

import Evergreen.V149.Compiler.AbstractDifferentialParser
import Evergreen.V149.Compiler.Acc
import Evergreen.V149.Parser.Block
import Evergreen.V149.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V149.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V149.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V149.Parser.Block.ExpressionBlock) Evergreen.V149.Compiler.Acc.Accumulator
