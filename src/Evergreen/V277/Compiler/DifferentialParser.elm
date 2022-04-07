module Evergreen.V277.Compiler.DifferentialParser exposing (..)

import Evergreen.V277.Compiler.AbstractDifferentialParser
import Evergreen.V277.Compiler.Acc
import Evergreen.V277.Parser.Block
import Evergreen.V277.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V277.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V277.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V277.Parser.Block.ExpressionBlock) Evergreen.V277.Compiler.Acc.Accumulator
