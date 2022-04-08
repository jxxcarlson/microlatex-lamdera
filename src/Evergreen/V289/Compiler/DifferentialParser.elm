module Evergreen.V289.Compiler.DifferentialParser exposing (..)

import Evergreen.V289.Compiler.AbstractDifferentialParser
import Evergreen.V289.Compiler.Acc
import Evergreen.V289.Parser.Block
import Evergreen.V289.Parser.PrimitiveBlock
import Tree


type alias EditRecord =
    Evergreen.V289.Compiler.AbstractDifferentialParser.EditRecord (Tree.Tree Evergreen.V289.Parser.PrimitiveBlock.PrimitiveBlock) (Tree.Tree Evergreen.V289.Parser.Block.ExpressionBlock) Evergreen.V289.Compiler.Acc.Accumulator
