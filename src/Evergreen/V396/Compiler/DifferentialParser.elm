module Evergreen.V396.Compiler.DifferentialParser exposing (..)

import Evergreen.V396.Compiler.AbstractDifferentialParser
import Evergreen.V396.Compiler.Acc
import Evergreen.V396.Parser.Block
import Evergreen.V396.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V396.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V396.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V396.Parser.Block.ExpressionBlock) Evergreen.V396.Compiler.Acc.Accumulator
