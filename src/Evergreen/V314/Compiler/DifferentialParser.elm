module Evergreen.V314.Compiler.DifferentialParser exposing (..)

import Evergreen.V314.Compiler.AbstractDifferentialParser
import Evergreen.V314.Compiler.Acc
import Evergreen.V314.Parser.Block
import Evergreen.V314.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V314.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V314.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V314.Parser.Block.ExpressionBlock) Evergreen.V314.Compiler.Acc.Accumulator
