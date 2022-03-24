module Evergreen.V154.Compiler.DifferentialParser exposing (..)

import Evergreen.V154.Compiler.AbstractDifferentialParser
import Evergreen.V154.Compiler.Acc
import Evergreen.V154.Parser.Block
import Evergreen.V154.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V154.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V154.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V154.Parser.Block.ExpressionBlock) Evergreen.V154.Compiler.Acc.Accumulator
