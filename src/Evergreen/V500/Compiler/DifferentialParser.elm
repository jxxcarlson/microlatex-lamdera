module Evergreen.V500.Compiler.DifferentialParser exposing (..)

import Evergreen.V500.Compiler.AbstractDifferentialParser
import Evergreen.V500.Compiler.Acc
import Evergreen.V500.Parser.Block
import Evergreen.V500.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V500.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V500.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V500.Parser.Block.ExpressionBlock) Evergreen.V500.Compiler.Acc.Accumulator
