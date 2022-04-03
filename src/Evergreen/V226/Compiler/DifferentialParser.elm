module Evergreen.V226.Compiler.DifferentialParser exposing (..)

import Evergreen.V226.Compiler.AbstractDifferentialParser
import Evergreen.V226.Compiler.Acc
import Evergreen.V226.Parser.Block
import Evergreen.V226.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V226.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V226.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V226.Parser.Block.ExpressionBlock) Evergreen.V226.Compiler.Acc.Accumulator
