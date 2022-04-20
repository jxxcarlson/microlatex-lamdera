module Evergreen.V430.Compiler.DifferentialParser exposing (..)

import Evergreen.V430.Compiler.AbstractDifferentialParser
import Evergreen.V430.Compiler.Acc
import Evergreen.V430.Parser.Block
import Evergreen.V430.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V430.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V430.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V430.Parser.Block.ExpressionBlock) Evergreen.V430.Compiler.Acc.Accumulator
